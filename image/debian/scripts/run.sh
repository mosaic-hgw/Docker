#!/bin/bash

#>available-env< TZ Europe/Berlin

# get commons
source ${HOME}/commons.sh

# show versions
echo -e "${LINE}\n\n  https://hub.docker.com/repository/docker/mosaicgreifswald\n\n${LINE}\n\n$(versions)\n\n${LINE}"

# test entrypoints write permissions
echoInfo "test write-permission in entrypoints"
entrypoints | awk '{print $3}' | grep -v '^$' | while read DIR; do
  if [ -w "$(realpath "${DIR}")" ]; then
    echoInfo "- ${DIR} -> ok $(mount | grep -q " $(realpath "${DIR}") " && echo "(volume/mount)")"
  elif mount | grep -q " ${DIR} "; then
    echoErr "- ${DIR} -> not permitted (volume/mount)"
  else
    echoWarn "- ${DIR} -> not permitted"
  fi
done
echo "${LINE}"

# test env-variables
echoInfo "check environment-variables"
ENV_ALL_FINE="y"
while read STATE VAR_OLD VAR_NEW; do if env | grep -q "^${VAR_OLD}="; then
  ENV_ALL_FINE="n"
  if [ "${STATE}" = "#>deprecated-env<" ]; then
    echoWarn "- WARNING You are using an obsolete variable that will be removed in one of the next versions: ${VAR_OLD}"
  elif [ "${STATE}" = "#>deleted-env<" ]; then
    echoErr "- ERROR You are using an old (ignored) variable: ${VAR_OLD}"
  fi
  [ "${VAR_NEW}x" != "x" ] && echoInfo "  -> Use instead: ${VAR_NEW}"
fi; done < <(find /entrypoint-* ${HOME} -maxdepth 4 -type f \( -iname '*.cli' -o -iname '*.env' -o -iname '*.sh' \) -exec grep -E "^#>de(preca|le)ted-env<" {} \; | sed 's/\r//')
[ "${ENV_ALL_FINE}" = "y" ] && echoSuc "environment-variables are fine."
echo "${LINE}"

# get run-scripts
RUN_SCRIPTS=$(cat "${HOME}/run.sh" | sed -n "/^### registered run-scripts/,//p" | tail -n+2 | sed "s/#//" | sort -k1 --sort=version)
echoInfo "$(echo "${RUN_SCRIPTS}" | wc -w) run-script(s) found to execute in following order and type"
for RUN_SCRIPT in ${RUN_SCRIPTS}; do echoInfo "- ${RUN_SCRIPT}"; done
if [ "$(echo ${RUN_SCRIPTS} | wc -w)" -eq "0" ]; then
  echoErr "no run-scripts found to start"
  exit
fi
echo "${LINE}"

MOSAIC_PIDS=()
checkRunningServices() {
  local EXIT_CODE
  if [ ${#MOSAIC_PIDS[@]} -gt 0 ]; then for PID in "${!MOSAIC_PIDS[@]}"; do if ! ls /proc/${PID}/exe > /dev/null 2>&1; then
    wait ${PID}
    EXIT_CODE=$?
    echoErr "$(echo "${MOSAIC_PIDS[$PID]}" | cut -d: -f1) is stopped (with exit-code ${EXIT_CODE})."
    unset "MOSAIC_PIDS[PID]"
    update_process_pids
    return ${EXIT_CODE}
  fi; done; fi
  return 0
}

stopRunningServices() {
  if [ ${#MOSAIC_PIDS[@]} -gt 0 ]; then for PID in "${!MOSAIC_PIDS[@]}"; do if ls /proc/${PID}/exe > /dev/null 2>&1; then
    echoInfo "stop $(echo "${MOSAIC_PIDS[$PID]}" | cut -d: -f1)"
    local PGID; PGID="$(awk '{print $5}' /proc/${PID}/stat)"
    kill -TERM -$PGID
    unset "MOSAIC_PIDS[PID]"
    update_process_pids
  fi; done; fi
}

startService() {
  local SCRIPT; SCRIPT="$(echo "${1}" | cut -d: -f1)"
  local STARTED_SCRIPT; STARTED_SCRIPT="$(echo "${1}" | cut -d: -f2)"
  local EXIT_CODE

  if [ "x${STARTED_SCRIPT}" != "x" ]; then
    echoInfo "start service ${SCRIPT} and wait for running with ${STARTED_SCRIPT}"
    echoDeb "${SCRIPT} &"
    ${SCRIPT} &
    MOSAIC_PIDS[$!]="${1}"
    update_process_pids
    while ! ${STARTED_SCRIPT} ; do
      checkRunningServices
      EXIT_CODE=$?
      [ ${EXIT_CODE} -gt 0 ] && break
      sleep 1
    done
  else
    echoInfo "start service ${SCRIPT}"
    echoDeb "${SCRIPT} &"
    ${SCRIPT} &
    MOSAIC_PIDS[$!]="${1}"
    update_process_pids
    EXIT_CODE=0 # ok
  fi

  return ${EXIT_CODE}
}

startAction() {
  local SCRIPT; SCRIPT="${1}"
  echoInfo "start action ${SCRIPT}"
  echoDeb "${SCRIPT} &"
  ${SCRIPT} &
  local PID=$!
  MOSAIC_PIDS[${PID}]="${SCRIPT}"
  update_process_pids
  wait ${PID}
  local EXIT_CODE=$?
  unset "MOSAIC_PIDS[PID]"
  update_process_pids
  return ${EXIT_CODE}
}

update_process_pids() {
  echo -n "" > ${HOME}/process_pids
  if [ ${#MOSAIC_PIDS[@]} -gt 0 ]; then for PID in "${!MOSAIC_PIDS[@]}"; do
    echo "${PID}=$(echo "${MOSAIC_PIDS[$PID]}" | cut -d: -f1)" >> ${HOME}/process_pids
  done; fi
}

SECONDS=0
for RUN_SCRIPT in ${RUN_SCRIPTS}; do
  TYPE=$(echo "${RUN_SCRIPT}" | cut -d: -f2)
  SCRIPT=$(echo "${RUN_SCRIPT}" | cut -d: -f3)
  STARTED=$(echo "${RUN_SCRIPT}" | cut -d: -f4)

  if ! checkRunningServices; then
    echoErr "one service is finished. abort all start processes."
    stopRunningServices
    exit 1
  fi

  case "${TYPE}" in
    service)
      startService "${SCRIPT}:${STARTED}"
      EXIT_CODE=$?
      if [ ${EXIT_CODE} -gt 0 ] ; then
        echoErr "cannot start service. abort all processes."
        stopRunningServices
        exit ${EXIT_CODE}
      fi
      ;;
    action)
      startAction "${SCRIPT}"
      EXIT_CODE=$?
      if [ ${EXIT_CODE} -gt 0 ] ; then
        echoErr "failed ${SCRIPT}, abort all start processes."
        stopRunningServices
        exit ${EXIT_CODE}
      else
        echoInfo "successfully finished action ${SCRIPT}"
      fi
      ;;
    *) echoErr "Unknown option: $1"; exit 1 ;;
  esac
done

#>available-env< MOS_RUN_MODE service
if [ "${MOS_RUN_MODE}" == "action" ]; then
  stopRunningServices
  exit 0
fi

echoSuc "all services started$([ "${SECONDS}" -gt "0" ] && echo " (${SECONDS}s)")"

#>available-env< MOS_SHUTDOWN_DELAY service
if [ -n "${MOS_SHUTDOWN_DELAY}" ]; then
  START_TIME=$(date +%s)
  echoWarn "shutdown all services in ${MOS_SHUTDOWN_DELAY}s"
fi

while true; do
  case "${MOS_RUN_MODE}" in
    service)
      if [ ${#MOSAIC_PIDS[@]} -gt 0 ]; then for PID in "${!MOSAIC_PIDS[@]}"; do if ! ls /proc/${PID}/exe > /dev/null 2>&1; then
        echo "$(echo "${MOSAIC_PIDS[$PID]}" | cut -d: -f1) ${SCRIPT}"
        if ! startService "${MOSAIC_PIDS[$PID]}"; then
          echoErr "cannot restart service. abort all processes."
        fi
        unset "MOSAIC_PIDS[PID]"
      fi; done; fi
      ;;
    cascade)
      if ! checkRunningServices; then
        EXIT_CODE=$?
        stopRunningServices
        exit ${EXIT_CODE}
      fi
      ;;
    *)
      # do nothing
      ;;
  esac

  if [ -n "${MOS_SHUTDOWN_DELAY}" ]; then
    CURRENT_TIME=$(date +%s)
    if [ "$((CURRENT_TIME - START_TIME))" -ge "${MOS_SHUTDOWN_DELAY}" ]; then
      echoWarn "shutdown all services"
      stopRunningServices
      exit 0
    fi
  fi

  sleep 5
done

### registered run-scripts
