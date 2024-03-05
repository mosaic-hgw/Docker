#!/bin/bash

# read parameters if exists
while [[ $# -gt 0 ]]; do case "$1" in
  --add-healthcheck-script=*) echo "${1#*=} || exit 1" >> "${HOME}/healthcheck.sh"; shift 1 ;;
  --add-run-script=*)         echo "#${1#*=}" >> "${HOME}/run.sh"; shift 1 ;;
  --add-entrypoint=*)         V=${1#*=}; printf "echo \"  %-27s: %s\"\n" "${V%%:*}" "${V#*:}" >> "${HOME}/entrypoints.sh"; shift 1 ;;
  --add-version=*)            V=${1#*=}; printf "echo \"  %-27s: %s\"\n" "${V%%:*}" "${V#*:}" >> "${HOME}/versions.sh"; shift 1 ;;
  --os-updated)               cat "${HOME}/versions.sh" | sed -r "s/(last {1}updated +: )[0-9 :-]+/\1$(date +"%F %T")/" > "${HOME}/versions.sh"; shift 1 ;;
  *)                          echo "Unknown option: $1"; exit 1 ;;
esac; done
