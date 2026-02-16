#!/bin/bash

# shellcheck disable=SC1091
source ./scripts/bash-color.sh

verbose="false"
enable_copr_build="false"

set_arguments() {
  local long_arguments="enable-copr-build,verbose"
  local short_arguments="v"
  local parsed_arguments

  parsed_arguments=$(getopt --options=$short_arguments --longoptions=$long_arguments --name "$0" -- "$@") || exit 1
  eval set -- "$parsed_arguments"

  while [ -n "$1" ]; do
    case "$1" in
    --verbose | -v)
      verbose="true"
      shift
      ;;
    --enable-copr-build)
      enable_copr_build="true"
      shift
      ;;
    --)
      shift
      ;;
    *)
      echo_error "Not an option: $1"
      usage
      exit 1
      ;;
    esac
  done
}
# shellcheck disable=SC2068
set_arguments $@

failed_commands=()
explicit_verbose="false"
enable_self_update="false"

test_command() {
  local command="$*"

  if [ "$enable_self_update" = "false" ]; then
    command+=" --disable-self-update"
  fi

  if [ "$verbose" = "true" ] || [ "$explicit_verbose" = "true" ]; then
    run_debug "$command"
  else
    $command &>/dev/null
  fi

  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    if [ "$explicit_verbose" = "false" ]; then
      failed_commands+=("$command")
    fi
    echo_error -n "Failed"
    echo " $command"
    return 1
  else
    echo_success -n "Success"
    echo " $command"
  fi
}

run_failed_commands() {
  local command
  for command in "${failed_commands[@]}"; do
    echo_error "$command"
    run_debug "$command"
    echo ""
  done
}

remove_submodules() {
  echo_color "Remove submodules"

  remove() {
    local submodule_dir="$1"
    if [ -d "$submodule_dir" ]; then
      git submodule deinit -f "$submodule_dir"
      git rm -f "$submodule_dir"
      rm -rf .git/modules/"$submodule_dir"
    fi
  }

  test_command remove "./copr_realtek-alc887-vd"
  test_command remove "./rpm-tools"
}

# Tests
build_local() {
  echo_color "Build RPM with local sources / patches"
  test_command ./rpm-tool build
}

build_without_local() {
  echo_color "Build RPM locally as it would in COPR"
  test_command ./rpm-tool build --without-local
}

build_copr() {
  echo_color "Build RPM on COPR"
  explicit_verbose="true"
  test_command ./rpm-tool copr-build --copr-watch
  explicit_verbose="false"
}

copr_status() {
  echo_color "Get COPR status"
  test_command ./rpm-tool copr-status
}

update_submodules() {
  echo_color "Update submodules + apply patches"
  test_command ./rpm-tool update --update-submodules --apply-patches
}

update_submodules_check_patches() {
  echo_color "Update submodules + check patches"
  test_command ./rpm-tool update --update-submodules --check-patches
}

update_self() {
  echo_color "Self update"
  enable_self_update="true"
  test_command ./rpm-tool update-self
  enable_self_update="false"
}

release() {
  echo_color "Create a release in git and update the RPM + Cargo"
  local test_spec_version
  local test_spec_tag

  local test_spec="./tests/rpm-tool-tag-test.spec"
  local test_cargo="./tests/Cargo.toml"
  local test_version="1.2.3"
  local is_failed="false"
  local test_cargo_dep="static_assertions"

  cp ./rpm-tool-tag.spec $test_spec
  cp ./Cargo.toml $test_cargo

  test_command ./rpm-tool release --spec-file="$test_spec" --cargo-file="$test_cargo" --no-push --new-version="$test_version" || return 1

  test_spec_version=$(grep "Version: " $test_spec)
  test_spec_tag=$(grep "%global tag v" $test_spec)
  test_cargo_version=$(grep --max-count=1 "version = " "$test_cargo")
  test_cargo_dep_version=$(grep --max-count=1 "${test_cargo_dep} = " "$test_cargo")

  echo "Version in spec file: $test_spec_version"
  echo "Tag in spec file: $test_spec_tag"
  echo "Version in Cargo.toml: $test_cargo_version"
  echo "Dependency version in Cargo.toml: $test_cargo_dep_version"

  # Checks
  if echo "$test_cargo_version" | grep "0.0.0" &>/dev/null; then
    echo_error "Failed: Failed to update Cargo version"
    is_failed="true"
  fi

  if echo "$test_cargo_dep_version" | grep "$test_version" &>/dev/null; then
    echo_error "Failed: Cargo dependency version got updated"
    is_failed="true"
  fi

  # Cleanup
  rm $test_spec
  rm $test_cargo
  rm "./tests/Cargo.lock"
  git tag -d "v${test_version}" || return 1
  git reset --soft HEAD~1 || return 1

  if [ "$is_failed" = "true" ]; then
    return 1
  fi
}

# Run tests
update_self
echo ""

release
echo ""

remove_submodules
echo ""

update_submodules
echo ""

update_submodules_check_patches
echo ""

build_local
echo ""

build_without_local
echo ""

if [ $enable_copr_build = "true" ]; then
  build_copr
  echo ""
fi

copr_status
echo ""

if [ ${#failed_commands[@]} -gt 0 ]; then
  echo_color "\nFailures:"
  run_failed_commands
fi
