#!/bin/bash

fail() {
  echo_error "$@\n"
  exit 1
}

install_dependencies() {
  if ! which getopt &>/dev/null; then
    echo_color "Installing util-linux"
    run_debug sudo dnf install util-linux -y --quiet || return 1
    echo ""
  fi
    if ! which git &>/dev/null; then
    echo_color "Installing git"
    run_debug sudo dnf install git -y --quiet || return 1
  fi
}
