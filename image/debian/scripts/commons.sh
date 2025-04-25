#!/bin/bash

#>available-env< MOS_DEBUG false

# colors
NC="$(printf "\033[0m")" # no color
GRAY="$(printf "\033[0;37m")"
DARK_GRAY="$(printf "\033[1;30m")"
RED="$(printf "\033[1;31m")"
DARK_RED="$(printf "\033[0;31m")"
GREEN="$(printf "\033[1;32m")"
DARK_GREEN="$(printf "\033[0;32m")"
YELLOW="$(printf "\033[1;33m")"
DARK_YELLOW="$(printf "\033[0;33m")"
BLUE="$(printf "\033[1;34m")"
DARK_BLUE="$(printf "\033[0;34m")"
PURPLE="$(printf "\033[1;35m")"
DARK_PURPLE="$(printf "\033[0;35m")"
CYAN="$(printf "\033[1;36m")"
DARK_CYAN="$(printf "\033[0;36m")"
WHITE="$(printf "\033[1;37m")"
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
  [[ ${MOS_DEBUG,,} =~ ^(true|yes|on|1)$ ]] && echoCol "${1}" "${2:-true}" "${3:-DARK_GRAY}" ":$(caller | awk '{ print $1 }')" 1>&2
}

echoCol() {
  local NEW_LINE=${2:-true}
  local -n COLOR=${3:-DEFAULT}
  local CALLER_LINE=${4}
  local LINE=""
  LINE="${COLOR}"
  ! [[ ${MOS_NO_TIME,,} =~ ^(true|yes|on|1)$ ]] && LINE="${LINE}$(date +%X.%3N) "
  [[ ${MOS_DEBUG,,} =~ ^(true|yes|on|1)$ ]] && LINE="${LINE}[${SELF_NAME}${CALLER_LINE}] "
  case $NEW_LINE in
    1 | true) echo -e "${LINE}$1${NC}" ;;
    *) echo -en "${LINE}$1${NC}" ;;
  esac
}