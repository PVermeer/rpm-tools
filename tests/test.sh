#!/bin/bash

source ./scripts/bash-color.sh

verbose="false"
enable_copr_build="false"

set_arguments() {
  local long_arguments="enable-copr-build,verbose"
  local short_arguments="v"

  local parsed_arguments=$(getopt --options=$short_arguments --longoptions=$long_arguments --name "$0" -- "$@") || exit 1
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
set_arguments $@

failed_commands=()
explicit_verbose="false"
enable_self_update="false"

test_command() {
  local command="$@"

  if [ "$enable_self_update" = "false" ]; then
    command+=" --disable-self-update"
  fi

  if [ "$verbose" = "true" ] || [ "$explicit_verbose" = "true" ]; then
    run_debug $command
  else
    $command &>/dev/null
  fi

  if [ $? -ne 0 ]; then
    if [ "$explicit_verbose" = "false" ]; then
      failed_commands+=("$command")
    fi
    echo_error -n "Failed"
    echo " $command"
  else
    echo_success -n "Success"
    echo " $command"
  fi
}

run_failed_commands() {
  local command
  for command in "${failed_commands[@]}"; do
    echo_error $command
    run_debug $command
    echo ""
  done
}

remove_submodules() {
  echo_color "Remove submodules"

  remove() {
    local submodule_dir="$1"
    if [ -d $submodule_dir ]; then
      git submodule deinit -f $submodule_dir
      git rm -f $submodule_dir
      rm -rf .git/modules/$submodule_dir
    fi
  }

  test_command remove "./copr_realtek-alc887-vd"
  test_command remove "./rpm-tools"
}

# Tests
build_local() {
  echo_color "Build RPM locally"
  test_command ./rpm-tool build
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
  echo_color "Update submodules"
  test_command ./rpm-tool update --update-submodules --apply-patches
}

update_self() {
  echo_color "Test self updater"
  enable_self_update="true"
  test_command ./rpm-tool build
  enable_self_update="false"
}

# Run tests
update_self
remove_submodules
update_submodules
build_local
if [ $enable_copr_build = "true" ]; then build_copr; fi
copr_status

if [ ${#failed_commands[@]} -gt 0 ]; then
  echo_color "\nFailures:"
  run_failed_commands
fi
