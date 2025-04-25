#!/bin/bash

# read parameters if exists
while [[ $# -gt 0 ]]; do case "$1" in
  --add-healthcheck-script=*)         echo "${1#*=} || exit 1" >> "${HOME}/healthcheck.sh"; shift 1 ;;
  --add-run-script=*|--add-process=*) "${HOME}/processes.sh" --add "${1#*=}"; shift 1 ;;
  --add-entrypoint=*)                 V=${1#*=}; printf "echo \"  %-29s: %s\"\n" "${V%%:*}" "${V#*:}" >> "${HOME}/entrypoints.sh"; shift 1 ;;
  --add-version=*)                    V=${1#*=}; printf "echo \"  %-27s: %s\"\n" "${V%%:*}" "${V#*:}" >> "${HOME}/versions.sh"; shift 1 ;;
  *)                                  echo "Unknown option: $1"; exit 1 ;;
esac; done
