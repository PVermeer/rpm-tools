#! /bin/bash

if [ -z "$spec_file" ]; then
  echo_error "spec_file = undefined"
  exit 1
fi
if [ -z "$no_push" ]; then
  echo_error "no_push = undefined"
  exit 1
fi
if [ -z "$RPM_SPEC_UPDATE" ]; then
  echo_error "RPM_SPEC_UPDATE = undefined"
  exit 1
fi

RPM_SPEC_VERSION_KEY="Version"
RPM_SPEC_TAG_KEY="%global tag"

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

create_release_in_git() {
  local new_version=$1
  local new_tag

  new_tag="v${new_version}"

  git --no-pager diff --compact-summary --color=always
  echo ""
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
  else
    echo "Enter new version (e.g. 1.2.3):"
    read -r new_release_version
  fi

  echo "New version: ${new_release_version}"
  validate_new_version "$current_version" "$new_release_version"

  echo_color -e "\nApplying new version: $new_release_version"

  echo_color -e "Updating spec file"
  update_version_in_spec_file "$spec_file" "$new_release_version"
  update_tag_in_spec_file "$spec_file" "$new_release_version"

  echo_color -e "\nCreating release in git"
  create_release_in_git "$new_release_version"

  RPM_SPEC_UPDATE="true"
}
