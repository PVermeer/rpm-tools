#!/bin/bash

fail() {
  echo_error "$@\n"
  exit 1
}

install_dependencies() {
  local missing_deps=""
  if ! which getopt &>/dev/null; then missing_deps+=" util-linux"; fi
  if ! which git &>/dev/null; then missing_deps+=" git"; fi
  if ! which jq &>/dev/null; then missing_deps+=" jq"; fi

  if [ -n "$missing_deps" ]; then
    echo -n "Installing packages: "
    echo_color "$missing_deps:"
    echo ""
    run_debug sudo dnf install -y --quiet $missing_deps || return 1
  else
    echo "No missing packages"
  fi
}
