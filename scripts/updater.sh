#!/bin/bash

update_self() {
  if ! which git >/dev/null; then
    echo_warning "Git not installed, not able to self update"
    return
  fi

  rpm_tools_submodule=$(get_submodule_path_from_url "https://github.com/pvermeer/rpm-tools") || true

  if [ -z "$rpm_tools_submodule" ]; then
    echo "Not installed as submodule, not able to self update"
    return
  fi

  if [ -n "$rpm_tools_submodule" ]; then
    if git submodule update --init -f $rpm_tools_submodule; then
      echo "Updated myself to latest git"
    else
      echo_warning "Could not update myself"
    fi
    return
  fi

  echo "No update found"
}
