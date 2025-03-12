#!/bin/bash

update_self() {
  if ! which git &>/dev/null; then
    echo_warning "Git not installed, not able to self update"
    return 1
  fi

  local git_repo="https://github.com/PVermeer/rpm-tools"
  local is_this_git_repo=$(git config --get remote.origin.url | grep -i "PVermeer/rpm-tools")
  if [ -n "$is_this_git_repo" ]; then
    echo "This is the main repo <PVermeer/rpm-tools>, no need to update"
    return 1
  fi

  local rpm_tools_submodule=$(get_submodule_path_from_url "$git_repo") || $(get_submodule_path_from_url "$git_repo.git") || true

  if [ -z "$rpm_tools_submodule" ]; then
    echo "Not installed as submodule, not able to self update"
    return 1
  fi

  if [ -n "$rpm_tools_submodule" ]; then
    local current_commit=$(git submodule status | grep $rpm_tools_submodule | awk '{ print $1 }')
    # Remove leading '+' if submodule update is not commited yet
    current_commit=$(echo $current_commit | sed "s/\+/""/")

    local latest_commit=$(git ls-remote "$git_repo" "HEAD" | awk 'NR==1{ print $1 }')

    if [ "$current_commit" != "$latest_commit" ]; then
      if git submodule update --init --remote -f $rpm_tools_submodule; then
        echo "Updated myself to latest git"
        return 0
      else
        echo_warning "Could not update myself"
        return 1
      fi
    fi
  fi

  echo "No update found"
  return 1
}
