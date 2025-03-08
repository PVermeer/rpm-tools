#!/bin/bash

get_global_vars_from_spec() {
  local spec_file=$1
  echo $(grep '^%global\s.*$' $spec_file | awk '{ print $2"="$3 }')
}

get_key() {
  echo $1 | awk -F '=' '{ print $1 }'
}
get_value() {
  echo $1 | awk -F '=' '{ print $2 }'
}
get_match_number() {
  echo $1 | grep -Eo '[0-9]+$' || echo ""
}

find_matching_branch() {
  local global_spec_vars
  local repo_match_number
  local branch

  global_spec_vars=$1
  repo_match_number=$2
  branch="HEAD"

  local keyValue
  for keyValue in $global_spec_vars; do
    local key
    local value

    key=$(get_key $keyValue)
    value=$(get_value $keyValue)

    if [[ $key = branch* ]]; then
      local branch_match_number
      branch_match_number=$(get_match_number $key)


      if [ "$repo_match_number" = "$branch_match_number" ]; then
        branch=$value
        break
      fi
    fi
  done

  echo $branch
}

find_matching_commit() {
  local global_spec_vars
  local repo_match_number
  local commit

  global_spec_vars=$1
  repo_match_number=$2

  local keyValue
  for keyValue in $global_spec_vars; do
    local key
    local value

    key=$(get_key $keyValue)
    value=$(get_value $keyValue)

    if [[ $key = commit* ]]; then
      local commit_key
      local commit_value
      local commit_match_number

      commit_key=$key
      commit_value=$value
      commit_match_number=$(get_match_number $commit_key)

      if [ "$repo_match_number" = "$commit_match_number" ]; then
        commit=$commit_value
        break
      fi
    fi
  done

  echo $commit
}

get_new_commit() {
  local repo
  local branch
  local new_commit

  repo=$1
  branch=$2
  new_commit=$(git ls-remote "$repo" $branch | awk '{ print $1 }') || return 1

  echo $new_commit
}

update_spec_repos() {
  local spec_file
  local global_spec_vars
  local rpm_updated

  spec_file=$1
  global_spec_vars=$(get_global_vars_from_spec $spec_file)
  rpm_updated="false"
 
  echo_color -e "Looking for remote changes\n"

  local keyValue
  for keyValue in $global_spec_vars; do
    local key
    local value

    key=$(get_key $keyValue)
    value=$(get_value $keyValue)

    if [[ ! $key = repository* ]]; then continue; fi

    local repo_key
    local repo_value
    local repo_match_number
    local branch
    local current_commit
    local new_commit

    repo_key=$key
    repo_value=$value
    repo_match_number=$(get_match_number $key)
    branch=$(find_matching_branch "$global_spec_vars" $repo_match_number)
    current_commit=$(find_matching_commit "$global_spec_vars" $repo_match_number)
    new_commit=$(get_new_commit $repo_value $branch || fail "Unable to get git ref")
    if [ -z $new_commit ]; then fail "Unable to get latest commit"; fi

    echo_color -n "$repo_value <$branch>:"
    echo " $current_commit -> $new_commit"

    # Checking for changes
    if [ "$current_commit" = "$new_commit" ]; then
      echo -e "\nNo change detected"
    else
      echo -e "\nChange detected"

      sed -i "s/%global\scommit$repo_match_number\s.*/%global commit$repo_match_number $new_commit/" ./$spec_file

      echo "RPM spec updated"
      RPM_SPEC_UPDATE="true"
    fi
    echo ""
  done
}
