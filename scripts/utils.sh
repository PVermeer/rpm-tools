#!/bin/bash

fail() {
  echo_error "$@\n"
  exit 1
}

export_variables_to_tmp() {
  echo_color "\n=== Exporting status ==="
  local status_file="$XDG_RUNTIME_DIR/rpm-tool-vars"
  echo "Writing status to $status_file"

  local status_vars=()
  status_vars+=("RPM_LOCAL_BUILD=$RPM_LOCAL_BUILD")
  status_vars+=("RPM_COPR_BUILD=$RPM_COPR_BUILD")
  status_vars+=("RPM_SPEC_UPDATE=$RPM_SPEC_UPDATE")
  status_vars+=("UPDATE_SELF=$UPDATE_SELF")
  status_vars+=("COPR_STATUS=$COPR_STATUS")

  touch $status_file
  (
    IFS=$'\n'
    echo "${status_vars[*]}" >$status_file
  )

  echo ""
  echo_success "Wrote status file > $status_file:"
  cat $status_file
  echo ""
}

check_dependencies() {
  local missing_deps=()
  if [ ! -f "/usr/bin/which" ]; then missing_deps+=("which"); fi
  if ! which getopt &>/dev/null; then missing_deps+=("util-linux"); fi
  if ! which git &>/dev/null; then missing_deps+=("git"); fi
  if ! which jq &>/dev/null; then missing_deps+=("jq"); fi
  if ! which rpmbuild &>/dev/null; then missing_deps+=("rpmbuild"); fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -n "Missing packages: "
    echo_color "${missing_deps[@]}"
  else
    echo "No missing packages"
  fi
}
