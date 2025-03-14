#!/bin/bash

spec_file=""
install_deps="false"
disable_self_update="false"
copr_webhook=""
build="false"
update="false"
update_self="false"
copr_build="false"
copr_watch="false"
copr_status="false"
copr_owner=""
copr_project=""
copr_package=""
update_submodules="false"
apply_patches="false"
without_local="false"

usage() {
  echo -e "$script_name usage:
    [ install-deps ] Precheck dependencies and install them (dnf)

    [ --spec-file SPEC-FILE ] Spec-file path
    [ --disable-self-update ] Disable self updating of this application

      [ build ] Build locally

      [ copr-build ] Trigger a build on COPR
        [ --copr-webhook URL ] COPR webhook url
        [ --copr-watch ] Watch the COPR build
          [ --copr-owner NAME ] COPR owner
          [ --copr-project PROJECT ] COPR project
          [ --copr-package PACKAGE NAME ] COPR package name

      [ copr-status ] Check build status on COPR
        [ --copr-owner NAME ] COPR owner
        [ --copr-project PROJECT ] COPR project
        [ --copr-package PACKAGE NAME ] COPR package name

      [ update ] Update the RPM spec file to latest commit(s)
        [ --update-submodules ] Update / Add submodules
        [ --apply-patches ] Apply patches to submodules
  
        Requires the spec file to have the following %global vars:
          [ %global repository<number> ] Url to repo
          [ %global commit<number> ] The latest commit on which the rpm was built
          [ %global branch<number> ] <optional=HEAD> The branch to check the latest commit on
          Match by incrementing the <number> values

      [ update-self ] Update this application as submodule

  Environment (can also be set in './.env'):
      DISABLE_SELF_UPDATE=
      SPEC_FILE=
      COPR_OWNER=
      COPR_PROJECT=
      COPR_PACKAGE=
      COPR_WEBHOOK=

  Exported variables $XDG_RUNTIME_DIR/rpm-tool-vars:
    RPM_LOCAL_BUILD=\"false\" || \"true\"
    RPM_COPR_BUILD=\"false\" || \"true\"
    RPM_SPEC_UPDATE=\"false\" || \"true\"
    SELF_UPDATE=\"false\" || \"true\"
    COPR_STATUS=\"status on copr\" || \"null\"
"
}

fail_arg() {
  echo_error "\n$@"
  usage
  echo ""
  exit 1
}

print_options() {
  echo "Using options:"

  echo_color -n "\tDISABLE_SELF_UPDATE:"
  echo " $disable_self_update"

  echo_color -n "\tSPEC_FILE:"
  echo " $spec_file"

  echo_color -n "\tCOPR_OWNER:"
  echo " $copr_owner"
  echo_color -n "\tCOPR_PROJECT:"
  echo " $copr_project"
  echo_color -n "\tCOPR_PACKAGE:"
  echo " $copr_package"
  echo_color -n "\tCOPR_WEBHOOK:"
  if [ -n "$copr_webhook" ]; then echo " ***"; else echo ""; fi
}

set_environment() {
  # Save global options set by user
  local env_disable_self_update=$DISABLE_SELF_UPDATE
  local env_spec_file=$SPEC_FILE
  local env_copr_owner=$COPR_OWNER
  local env_copr_project=$COPR_PROJECT
  local env_copr_package=$COPR_PACKAGE
  local env_copr_webhook=$COPR_WEBHOOK

  # Override global options with .env file
  if [ -f "./.env" ]; then
    echo -e "Found environment file"
    source "./.env"
  fi

  # Set options from .env file (prio 3)
  if [ -n "$DISABLE_SELF_UPDATE" ]; then disable_self_update=$DISABLE_SELF_UPDATE; fi
  if [ -n "$SPEC_FILE" ]; then spec_file=$SPEC_FILE; fi
  if [ -n "$COPR_OWNER" ]; then copr_owner=$COPR_OWNER; fi
  if [ -n "$COPR_PROJECT" ]; then copr_project=$COPR_PROJECT; fi
  if [ -n "$COPR_PACKAGE" ]; then copr_package=$COPR_PACKAGE; fi
  if [ -n "$COPR_WEBHOOK" ]; then copr_webhook=$COPR_WEBHOOK; fi

  # Set global options set by user (prio 2)
  if [ -n "$env_disable_self_update" ]; then disable_self_update=$env_disable_self_update; fi
  if [ -n "$env_spec_file" ]; then spec_file=$env_spec_file; fi
  if [ -n "$env_copr_owner" ]; then copr_owner=$env_copr_owner; fi
  if [ -n "$env_copr_project" ]; then copr_project=$env_copr_project; fi
  if [ -n "$env_copr_package" ]; then copr_package=$env_copr_package; fi
  if [ -n "$env_copr_webhook" ]; then copr_webhook=$env_copr_webhook; fi

  # Prio 1 are the passed arguments
}

set_arguments() {
  local long_arguments="help,disable-self-update,spec-file:,copr-webhook:,copr-owner:,copr-project:,copr-package:,copr-watch,update-submodules,apply-patches,without-local,install-deps,update-self,build,update,copr-build,copr-status"
  local short_arguments=""

  local parsed_arguments=$(getopt --options=$short_arguments --longoptions=$long_arguments --name "$0" -- "$@") || exit 1
  eval set -- "$parsed_arguments"

  while [ -n "$1" ]; do
    case "$1" in
    --help)
      usage
      exit 0
      ;;
    --disable-self-update)
      disable_self_update="true"
      shift
      ;;
    --spec-file)
      spec_file="$2"
      shift 2
      ;;
    --copr-webhook)
      copr_webhook="$2"
      shift 2
      ;;
    --copr-owner)
      copr_owner="$2"
      shift 2
      ;;
    --copr-project)
      copr_project="$2"
      shift 2
      ;;
    --copr-package)
      copr_package="$2"
      shift 2
      ;;
    --copr-watch)
      copr_watch="true"
      shift
      ;;
    --update-submodules)
      update_submodules="true"
      shift
      ;;
    --apply-patches)
      apply_patches="true"
      shift
      ;;
    --without-local)
      without_local="true"
      shift
      ;;
    build)
      build="true"
      shift
      ;;
    update)
      update="true"
      shift
      ;;
    copr-build)
      copr_build="true"
      shift
      ;;
    copr-status)
      copr_status="true"
      shift
      ;;
    update-self)
      update_self="true"
      shift
      ;;
    install-deps)
      install_deps="true"
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
