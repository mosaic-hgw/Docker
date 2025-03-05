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

${WILDFLY_HOME}/enable_keystore.sh
EXIT_CODE=$?
if [ ${EXIT_CODE} -ne 0 ]; then
    echoErr "keystore-test has failed"
    exit ${EXIT_CODE}
fi

echo "${LINE}"

${WILDFLY_HOME}/add_jboss_cli.sh
EXIT_CODE=$?
if [ ${EXIT_CODE} -ne 0 ]; then
    echoErr "jboss-cli is interrupted"
    exit ${EXIT_CODE}
fi

[[ "${WF_MARKERFILES,,}" == "false" ]] && ${WILDFLY_HOME}/sync_deployments.sh &

rm -f ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/*

WF_OPTS="-Djboss.server.log.dir=${ENTRY_LOGS}/wildfly $([[ ${WF_DEBUG,,} =~ ^(true|yes|on|1)$ ]] && echo "--debug")"
${WILDFLY_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 ${WF_OPTS}
