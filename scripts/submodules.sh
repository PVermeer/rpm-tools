#!/bin/bash

get_submodule_path_from_url() {
  local url=$1
  local config_path
  local path

  config_path=$(git config --file .gitmodules --get-regexp url | grep "$url" | awk '{ print $1 }' | awk -F "." '{ print $1"."$2 }' | head -n 1)

  if [ -z "$config_path" ]; then return 1; fi

  path=$(git config --file .gitmodules "$config_path.path") || return 1

  echo $path
}

get_submodule_paths() {
  local config_paths
  local submodule_paths=""

  config_paths=$(git config --file .gitmodules --get-regexp url | awk '{ print $1 }' | awk -F "." '{ print $1"."$2 }')

  local config_path
  for config_path in $config_paths; do
    local path
    path=$(git config --file .gitmodules "$config_path.path")
    submodule_paths+=" $path"
  done

  echo $submodule_paths
}

add_submodule() {
  local repo
  repo=$1

  echo -en "\nAdding new submodule: "
  echo_color -e "$repo"
  git submodule add $repo
}

update_submodules() {
  local global_spec_vars
  global_spec_vars=$(get_global_vars_from_spec $spec_file)

  local keyValue
  for keyValue in $global_spec_vars; do
    local key
    local value
    local repo

    key=$(get_key $keyValue)
    value=$(get_value $keyValue)

    if [[ ! $key = repository* ]]; then continue; fi
    repo=$value

    # Add repo if not in .gitmodules
    if [ ! -f ./.gitmodules ]; then
      add_submodule $repo
    fi

    local submodule_path
    local repo_match_number
    local commit
    local branch

    submodule_path=$(get_submodule_path_from_url $repo) || echo ""

    if [ -z "$submodule_path" ]; then
      add_submodule $repo || continue
      submodule_path=$(get_submodule_path_from_url $repo)
    fi

    if [ -z "$submodule_path" ]; then
      fail "Could not add submodule"
    fi

    repo_match_number=$(get_match_number $key)
    commit=$(find_matching_commit "$global_spec_vars" $repo_match_number)
    branch=$(find_matching_branch "$global_spec_vars" $repo_match_number)

    if [ -z "$commit" ]; then
      fail "Could not get commit for reset"
    fi

    echo -en "Resetting submodule: "
    echo_color -e "$repo"
    cd "./$submodule_path"
    if [ -n $branch ] && [ "$branch" != "HEAD" ]; then
      git switch $branch
    fi
    git reset --hard $commit
    echo ""
    cd ..
  done
}

apply_patches() {
  local submodule_paths

  if [ ! -f ./.gitmodules ]; then
    echo_warning "No submodules in repo"
    return
  fi
  submodule_paths=$(get_submodule_paths)

  local path
  for path in $submodule_paths; do
    local patch_files="../patches/$path/*.patch"
    
    cd "./$path"

    # One-by-one so the filename of the patch is printed
    set +e

    if ls $patch_files 1> /dev/null 2>&1; then
      local file
      for file in ../patches/$path/*.patch; do
        echo_color "\nPatching <$file>:"
        git apply -v $file
      done
    else
      echo -n "No patches for "
      echo_color "$path"
    fi
    set -e

    cd ".."
  done
}
