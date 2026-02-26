#! /bin/bash

if [ -z "$script_dir" ]; then
  echo_error "script_dir = undefined"
  exit 1
fi
if [ -z "$spec_file" ]; then
  echo_error "spec_file = undefined"
  exit 1
fi
if [ -z "$no_push" ]; then
  echo_error "no_push = undefined"
  exit 1
fi
if [ -z "$bump_version" ]; then
  echo_error "bump_version = undefined"
  exit 1
fi
if [ -z "$RPM_SPEC_UPDATE" ]; then
  echo_error "RPM_SPEC_UPDATE = undefined"
  exit 1
fi

RPM_SPEC_VERSION_KEY="Version"
RPM_SPEC_TAG_KEY="%global tag"

CARGO_VERSION_KEY="version"

get_current_version() {
  local spec_file=$1
  local current_version_line
  local current_version

  current_version_line=$(grep "${RPM_SPEC_VERSION_KEY}: " "$spec_file")
  current_version="${current_version_line#"${RPM_SPEC_VERSION_KEY}: "}"

  echo "$current_version"
}

validate_new_version() {
  local current_version=$1
  local new_version=$2

  local current_version_major
  local current_version_minor
  local current_version_patch
  local new_version_major
  local new_version_minor
  local new_version_patch

  if [[ ! $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo_error "Invalid semantic version"
    return 1
  fi

  current_version_major=$(echo "$current_version" | awk -F '.' '{ print $1 }')
  current_version_minor=$(echo "$current_version" | awk -F '.' '{ print $2 }')
  current_version_patch=$(echo "$current_version" | awk -F '.' '{ print $3 }')

  new_version_major=$(echo "$new_version" | awk -F '.' '{ print $1 }')
  new_version_minor=$(echo "$new_version" | awk -F '.' '{ print $2 }')
  new_version_patch=$(echo "$new_version" | awk -F '.' '{ print $3 }')

  if [ "$new_version" = "$current_version" ]; then
    echo_error "Version not upgraded, please upgrade the version"
    return 1
  fi
  if [[ "$new_version_major" < "$current_version_major" ]]; then
    echo_error "Major version is lower then current version"
    return 1
  fi
  if [[ "$new_version_major" == "$current_version_major" && "$new_version_minor" < "$current_version_minor" ]]; then
    echo_error "Minor version is lower then current version"
    return 1
  fi
  if [[ "$new_version_major" == "$current_version_major" && "$new_version_minor" == "$current_version_minor" && "$new_version_patch" < "$current_version_patch" ]]; then
    echo_error "Minor version is lower then current version"
    return 1
  fi
}

update_version_in_spec_file() {
  local spec_file=$1
  local new_version=$2

  local current_version_line

  current_version_line=$(grep "${RPM_SPEC_VERSION_KEY}: " "$spec_file") || {
    echo_error "Failed to get version key in spec file"
    return 1
  }

  sed -i "s/${current_version_line}/${RPM_SPEC_VERSION_KEY}: ${new_version}/" "$spec_file" || {
    echo_error "Failed to update version in spec file"
    return 1
  }
}

update_tag_in_spec_file() {
  local spec_file=$1
  local new_version=$2

  local new_tag
  local current_tag_line

  new_tag="v${new_version}"
  current_tag_line=$(grep "${RPM_SPEC_TAG_KEY} v" "$spec_file") || {
    echo_error "Failed to get tag key in spec file"
    return 1
  }

  sed -i "s/$current_tag_line/${RPM_SPEC_TAG_KEY} ${new_tag}/" "$spec_file" || {
    echo_error "Failed to update tag in spec file"
    return 1
  }
}

update_version_in_cargo() {
  local new_version=$1
  local cargo_file_default="./Cargo.toml"
  local cargo_file=${cargo_file:-$cargo_file_default}

  if [ -f "$cargo_file" ] && which cargo &>/dev/null; then
    echo "Updating version in ${cargo_file}"
  else
    return 0
  fi

  local current_version_line

  current_version_line=$(grep --max-count=1 "${CARGO_VERSION_KEY} = " "$cargo_file") || {
    echo_error "Failed to get version key in ${cargo_file}"
    return 1
  }

  # First, fetch all deps, cargo will refuse to update lockfile otherwise
  # This must be online but version locked
  cargo fetch --manifest-path "$cargo_file" --locked || {
    echo_error "Failed to fetch crates from ${cargo_file}"
    return 1
  }

  # Then update version
  sed -i "0,/${current_version_line}/s/${current_version_line}/${CARGO_VERSION_KEY} = \"${new_version}\"/" "$cargo_file" || {
    echo_error "Failed to update version in ${cargo_file}"
    return 1
  }

  # Last, update lockfile with updated app version
  # This must be offline so it only updates the app version
  cargo generate-lockfile --manifest-path "$cargo_file" --offline || {
    echo_error "Failed to generate a new lockfile from ${cargo_file}"
    return 1
  }
}

create_release_in_git() {
  local new_version=$1
  local new_tag

  new_tag="v${new_version}"

  git --no-pager diff --compact-summary --color=always
  echo ""
  git add --all
  git commit -am "chore(release): ${new_version}" || true
  git tag -a "${new_tag}" -m "Release version ${new_version}"
  if [ "$no_push" = "false" ]; then
    git push --follow-tags
  fi
}

release() {
  local current_version
  local new_release_version

  current_version=$(get_current_version "$spec_file")
  echo "Current version: ${current_version}"

  if [ -n "$new_version" ]; then
    new_release_version=$new_version
  elif [ "$bump_version" = "true" ]; then
    local bumped_version
    bumped_version=$(git-cliff --config="${script_dir}/cliff.toml" --bumped-version) # v1.2.3 format
    new_release_version=${bumped_version#v}
  else
    echo "Enter new version (e.g. 1.2.3):"
    read -r new_release_version
  fi

  echo "New version: ${new_release_version}"
  if ! validate_new_version "$current_version" "$new_release_version"; then
    if [ "$bump_version" = "true" ]; then
      echo_warning "If ${new_release_version} <= ${current_version}: Please create a the tag 'v${current_version}' in git"
    fi
    return 1
  fi

  echo_color -e "\nApplying new version: $new_release_version"

  echo_color -e "Generating CHANGELOG.md"
  git-cliff --config="${script_dir}/cliff.toml" -o --bump

  echo_color -e "Updating spec file"
  update_version_in_spec_file "$spec_file" "$new_release_version"
  update_tag_in_spec_file "$spec_file" "$new_release_version"

  update_version_in_cargo "$new_release_version"

  echo_color -e "\nCreating release in git"
  create_release_in_git "$new_release_version"

  RPM_SPEC_UPDATE="true"
}
