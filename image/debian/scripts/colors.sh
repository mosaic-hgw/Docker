#!/bin/bash

# colors
NC="$(printf "\033[0m")" # no color
DARK_GRAY="$(printf "\033[1;30m")"
RED="$(printf "\033[1;31m")"
GREEN="$(printf "\033[1;32m")"
YELLOW="$(printf "\033[1;33m")"
BLUE="$(printf "\033[1;34m")"
PURPLE="$(printf "\033[1;35m")"
CYAN="$(printf "\033[1;36m")"
WHITE="$(printf "\033[1;1m")"
UNDERLINE="$(printf "\033[4m")"
BLINKING="$(printf "\033[5m")"

LINE="========================================================================="
SELF_NAME="$(basename "$0")"

echoErr() {
  echoCol "${1}" "${2:-true}" "${3:-RED}" ":$(caller | awk '{ print $1 }')" 1>&2
}

echoWarn() {
  echoCol "${1}" "${2:-true}" "${3:-YELLOW}" ":$(caller | awk '{ print $1 }')" 1>&2
}

echoInfo() {
  echoCol "${1}" "${2:-true}" "${3:-NC}" ":$(caller | awk '{ print $1 }')"
}

echoSuc() {
  echoCol "${1}" "${2:-true}" "${3:-GREEN}" ":$(caller | awk '{ print $1 }')"
}

echoDeb() {
  [ "${DEBUG}" ] && echoCol "${1}" "${2:-true}" "${3:-DARK_GRAY}" ":$(caller | awk '{ print $1 }')" 1>&2
}

echoCol() {
  local NEW_LINE=${2:-true}
  local -n COLOR=${3:-DEFAULT}
  local CALLER_LINE=${4}
  local LINE="[${SELF_NAME}${CALLER_LINE}] $1"
  case $NEW_LINE in
    1 | true) echo -e "${COLOR}${LINE}${NC}" ;;
    *) echo -en "${COLOR}${LINE}${NC}" ;;
  esac
}