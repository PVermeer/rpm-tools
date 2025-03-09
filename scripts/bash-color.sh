#!/bin/bash

blue='\033[1;34m'
teal='\033[1;36m'
green='\033[1;32m'
yellow='\033[1;33m'
orange='\033[38:5:202m'
red='\033[1;31m'
pink='\033[38:5:205m'
purple='\033[1;35m'
slate='\033[38:5:67m'
cyan_dim='\033[2;36m'
removecolor='\033[0m'
arrow='➜'
themecolor=$purple
errorcolor=$red
warningcolor=$yellow
successcolor=$green
tracecolor=$cyan_dim

THEME=$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null || echo "'purple'")
THEME=${THEME//\'/}

case $THEME in
"blue")
  themecolor=$blue
  ;;
"green")
  themecolor=$green
  ;;
"orange")
  themecolor=$orange
  ;;
"pink")
  themecolor=$pink
  ;;
"purple")
  themecolor=$purple
  ;;
"red")
  themecolor=$red
  ;;
"slate")
  themecolor=$slate
  ;;
"teal")
  themecolor=$teal
  ;;
"yellow")
  themecolor=$yellow
  ;;
*)
  themecolor=$purple
  ;;
esac

parse_arguments() {
  switches=""
  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -e)
      switches+=" $1"
      shift
      ;;
    -n)
      switches+=" $1"
      shift
      ;;
    -ne)
      switches+=" $1"
      shift
      ;;
    -en)
      switches+=" $1"
      shift
      ;;
    *)
      break
      ;;
    esac
  done
  arguments="$@"

  # Some shells (github actions!) dont pass the color
  # to the next line when provided before `\n`
  if [ "${arguments:0:2}" = "\n" ]; then
    arguments="${arguments#\\n}"
    echo ""
  fi
}

# Set stderr color
exec 9>&2
exec 8> >(
  while IFS='' read -r line || [ -n "$line" ]; do
    echo -e "${errorcolor}${line}${removecolor}"
  done
)
function undirect() { exec 2>&9; }
function redirect() { exec 2>&8; }
trap "redirect;" DEBUG
PROMPT_COMMAND='undirect;'
export BASH_XTRACEFD=1 # set -x to stdout

# Trace color `set -x`
exec 7> >(
  while IFS='' read -r line || [ -n "$line" ]; do
    echo -e "\t${tracecolor}${line}${removecolor}"
  done
)

# Color wrapper
echo_color() {
  local arguments=$@
  parse_arguments $arguments
  echo -e $switches "${themecolor}$arguments${removecolor}"
}

echo_error() {
  local arguments=$@
  parse_arguments $arguments
  echo -e $switches "${errorcolor}✕ $arguments${removecolor}"
}

echo_warning() {
  local arguments=$@
  parse_arguments $arguments
  echo -e $switches "${warningcolor}! $arguments${removecolor}"
}

echo_success() {
  local arguments=$@
  parse_arguments $arguments
  echo -e $switches "${successcolor}✓ $arguments${removecolor}"
}

echo_debug() {
  local arguments=$@
  parse_arguments $arguments
  echo -e $switches "${tracecolor}✓ $arguments${removecolor}"
}

# Trace colors for set -x
run_debug() {
  local BASH_XTRACEFD=7
  local command="${@@Q}"
  eval $command >&7
}

on_exit() {
  unset BASH_XTRACEFD
}
trap on_exit EXIT
