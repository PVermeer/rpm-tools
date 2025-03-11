#!/bin/bash

fail() {
  echo_error "$@\n"
  exit 1
}

export_variables_to_tmp() {
  local status_file="$XDG_RUNTIME_DIR/rpm-tool-vars"
  touch $status_file

  local status_vars="\n
  RPM_LOCAL_BUILD="$RPM_LOCAL_BUILD"\n
  RPM_COPR_BUILD="$RPM_COPR_BUILD"\n
  RPM_SPEC_UPDATE="$RPM_SPEC_UPDATE"\n
  UPDATE_SELF="$UPDATE_SELF"\n
  COPR_STATUS="$COPR_STATUS"
  "
  echo -e $status_vars > $status_file

  echo_color -e "\nStatus file <$status_file>:"
  cat $status_file
  echo ""
}

install_dependencies() {
  if [ ! -f "/usr/bin/which" ]; then
    echo -n "Installing: "
    echo_color "which"
    run_debug sudo dnf install -y --quiet which 2>/dev/null || return 1
  fi

  local missing_deps=""
  if ! which getopt &>/dev/null; then missing_deps+=" util-linux"; fi
  if ! which git &>/dev/null; then missing_deps+=" git"; fi
  if ! which jq &>/dev/null; then missing_deps+=" jq"; fi

  if [ -n "$missing_deps" ]; then
    echo -n "Installing packages: "
    echo_color "$missing_deps:"
    echo ""
    run_debug sudo dnf install -y --quiet $missing_deps 2>/dev/null || return 1
  else
    echo "No missing packages"
  fi
}
