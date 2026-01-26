#!/bin/bash

# get commons
source ${HOME}/commons.sh

echo "${LINE}"
echo
echo "  This is a Docker image for the Java application server WildFly. The"
echo "  image is based on slim debian-image and prepared for the tools of the"
echo "  university medicine greifswald (but can also be used for other similar"
echo "  projects)."
echo

${WILDFLY_HOME}/create_wildfly_admin.sh

if [[ ! ${WF_MARKERFILES,,} =~ ^(true|false|yes|no|on|off|1|0)$ ]]; then
    echo "${LINE}"
    echoInfo "test write-permission in folder ${ENTRY_WILDFLY_DEPLOYS}"
    MF_TESTFILE=${ENTRY_WILDFLY_DEPLOYS}/mf.test
    WF_MARKERFILES="false"
    touch ${MF_TESTFILE}.1 2>/dev/null
    if [ -e ${MF_TESTFILE}.1 ]; then
      touch ${MF_TESTFILE}.2 -r ${MF_TESTFILE}.1
      if [ "" = "$(stat -c %y ${MF_TESTFILE}.* | uniq -u)" ]; then
        echoInfo "write-permission detected -> WF_MARKERFILES=true"
        WF_MARKERFILES="true"
      else
        echoInfo "write-permission detected, but not POSIX-conform -> WF_MARKERFILES=false"
      fi
    else
      echoInfo "no write-permission detected -> WF_MARKERFILES=false"
    fi
    rm ${MF_TESTFILE}.* 2>/dev/null
fi

if [[ "${WF_MARKERFILES,,}" != "$(cat ${MOS_READY_PATH}/markerfiles_mode)" ]]; then
    echo -n "${WF_MARKERFILES,,}" > ${MOS_READY_PATH}/markerfiles_mode
    if [[ ${WF_MARKERFILES,,} =~ ^(false|no|off|0)$ ]]; then
        echo "/subsystem=deployment-scanner/scanner=default:write-attribute(name=\"scan-enabled\",value=true)" > "${WILDFLY_HOME}/internal_cli/markerfiles.cli"
        echo "/subsystem=deployment-scanner/scanner=entrypoint:write-attribute(name=\"scan-enabled\",value=false)" >> "${WILDFLY_HOME}/internal_cli/markerfiles.cli"
    else
        echo "/subsystem=deployment-scanner/scanner=default:write-attribute(name=\"scan-enabled\",value=false)" > "${WILDFLY_HOME}/internal_cli/markerfiles.cli"
        echo "/subsystem=deployment-scanner/scanner=entrypoint:write-attribute(name=\"scan-enabled\",value=true)" >> "${WILDFLY_HOME}/internal_cli/markerfiles.cli"
    fi
    rm -f "${MOS_READY_PATH}/markerfiles.cli.completed"
fi

unset EXIT_CODE
bash ${WILDFLY_HOME}/enable_keystore.sh
EXIT_CODE=$?
if [ -z "${EXIT_CODE}" ]; then
    echoErr "keystore-test was not run"
    exit 1
elif [ ${EXIT_CODE} -ne 0 ]; then
    echoErr "keystore-test has failed"
    exit ${EXIT_CODE}
fi

echo "${LINE}"

unset EXIT_CODE
bash ${WILDFLY_HOME}/add_jboss_cli.sh
EXIT_CODE=$?
if [ -z "${EXIT_CODE}" ]; then
    echoErr "jboss-cli was not run"
    exit 1
elif [ ${EXIT_CODE} -ne 0 ]; then
    echoErr "jboss-cli is interrupted"
    exit ${EXIT_CODE}
fi

# wait for ports
if [ -n "${WF_WAIT_FOR_PORTS}" ]; then
  echoInfo "wait for ports found: ${WF_WAIT_FOR_PORTS}"
  echo "${LINE}"
  default_timeout=300
  default_sleep=0
  waiting_pids=()
  for wait_for in $(echo "${WF_WAIT_FOR_PORTS}" | tr ' ,;' '\n' | awk -F: '{if(NF==2){$0=$0":'${default_timeout}':'${default_sleep}'"}else if(NF==3){$0=$0":'${default_sleep}'"}print}' | sort -t: -k3,3n | paste -sd' ' -); do
    IFS=':' read -r i_host i_port i_timeout i_sleep <<< "${wait_for}"
    ( wait-for-it "${i_host}:${i_port}" -t "${i_timeout:-${default_timeout}}" && ( ([ "${i_sleep}" -gt 0 ] && echoInfo "sleep ${i_sleep}s after ${i_host}:${i_port}" && sleep "${i_sleep}") || exit 0) ) & waiting_pids+=($!)
  done
  for waiting_pid in "${waiting_pids[@]}"; do
    wait "${waiting_pid}" || exit $?
  done
fi

if [[ "${WF_MARKERFILES,,}" == "false" ]]; then
  bash ${WILDFLY_HOME}/sync_deployments.sh &

#>available-env< WF_DISABLE_DEPLOYMENTS_BY_REGEX
elif [ -n "${WF_DISABLE_DEPLOYMENTS_BY_REGEX}" ] && ls ${ENTRY_WILDFLY_DEPLOYS}/ | grep -qE "${WF_DISABLE_DEPLOYMENTS_BY_REGEX}" >/dev/null 2>1; then
    echoInfo "Disable Deployments by regular expression (WF_DISABLE_DEPLOYMENTS_BY_REGEX)"
    DEP_NAMES="$(ls ${ENTRY_WILDFLY_DEPLOYS}/* | grep -E "${WF_DISABLE_DEPLOYMENTS_BY_REGEX}")"
    for DEP_NAME in ${DEP_NAMES}; do
        [[ $(basename "${DEP_NAME,,}") =~ \.((un)?deployed|isdeploying|skipdeploy) ]] && continue
        if touch --reference="${DEP_NAME}" "${DEP_NAME}.skipdeploy"; then
            echoInfo ">>> disable $(basename "${DEP_NAME}")"
        else
            echoErr ">>> can not disable $(basename "${DEP_NAME}"), permission denied"
            exit 125
        fi
    done
    echo "${LINE}"
fi

rm -f ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/*

WF_OPTS="-Djboss.server.log.dir=${ENTRY_LOGS}/wildfly $([[ ${WF_DEBUG,,} =~ ^(true|yes|on|1)$ ]] && echo "--debug")"
bash ${WILDFLY_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 ${WF_OPTS}

echoWarn "WildFly-Server is stopped"
