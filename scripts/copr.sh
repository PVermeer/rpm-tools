#!/bin/bash

build_on_copr() {
  if [ -z $copr_webhook ]; then
    fail_arg "Please provide the COPR webhook --copr-webhook"
  fi

  echo "Sending build request to Copr"

  curl --fail-with-body --no-progress-meter -X POST $copr_webhook || fail "The COPR webhook failed"

  RPM_COPR_BUILD="true"
}

get_copr_status() {
  if [ -z $copr_owner ] || [ -z $copr_project ] || [ -z $copr_package ]; then
    fail_arg "Please provide all COPR information"
  fi

  local response=$(curl -s -X 'GET' \
    "https://copr.fedorainfracloud.org/api_3/package/?ownername=$copr_owner&projectname=$copr_project&packagename=$copr_package&with_latest_build=true&with_latest_succeeded_build=false" \
    -H 'accept: application/json')

  local build_state="$(echo $response | jq -r '.builds.latest.state')"
  local error="$(echo $response | jq -r '.error')"

  if [ "$error" = "null" ]; then
    echo $build_state
    return 0
  fi

  echo $error
  return 1
}

copr_watch() {
  echo_color "\nWatching COPR build status"

  local build_state=""
  until [ "$build_state" = "succeeded" ] || [ "$build_state" = "failed" ] || [ "$build_state" = "canceled" ]; do

    on_error() {
      echo_error "$build_state"
      build_state="null"
      COPR_STATUS="$build_state"
    }
    build_state=$(get_copr_status) || on_error
    COPR_STATUS="$build_state"

    if [ "$build_state" = "succeeded" ]; then
      echo "Copr build status: $(echo_success $build_state) on $(date)"
      break
    elif [ "$build_state" = "failed" ]; then
      echo "Copr build status: $(echo_error $build_state) on $(date)"
      exit 1
    elif [ "$build_state" = "null" ] || [ -z "$build_state" ]; then
      fail "Could not get build state from COPR on $(date)"
    elif [ "$build_state" = "canceled" ] || [ -z "$build_state" ]; then
      fail "Copr build has been canceled on $(date)"
    else
      echo "Copr build status: $(echo_warning $build_state) on $(date)"
      sleep 10
    fi
  done
}
