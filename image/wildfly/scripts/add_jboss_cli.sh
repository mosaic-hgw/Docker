#!/bin/bash

# get colors
source ${HOME}/colors.sh

SECONDS=0
if [ "$WF_ADD_CLI_FILTER" ]; then
    CLI_FILTER="(\.cli|\.${WF_ADD_CLI_FILTER/[, |]+/|\.})"
else
    CLI_FILTER="\.cli"
fi

BATCH_FILES=$(comm -23 --nocheck-order <(ls /entrypoint-wildfly-cli ${WILDFLY_HOME}/internal_cli 2> /dev/null | grep -v "/" | grep -E "$CLI_FILTER$" | grep -v .completed) \
    <(ls ${MOS_READY_PATH} 2> /dev/null | grep .completed | sed "s/\.completed$//"))

echoInfo "$(echo ${BATCH_FILES} | wc -w) cli-file(s) found to execute with jboss-cli.sh"
echoInfo "filter: ${CLI_FILTER}"
echoInfo "${BATCH_FILES}" | tr "\\n" "," | sed "s/,$//"
echo

if [ $(echo ${BATCH_FILES} | wc -w) -gt 0 ]; then
    env > env.properties
    touch ${MOS_READY_PATH}/jboss_cli_block

    ${WILDFLY_HOME}/bin/standalone.sh --admin-only &
    until `${JBOSS_CLI} -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done;

    for BATCH_FILE in ${BATCH_FILES}; do
        if [ -f "/entrypoint-wildfly-cli/${BATCH_FILE}" ]; then
            echoInfo "execute jboss-batchfile \"${BATCH_FILE}\""
            ${JBOSS_CLI} -c --properties=env.properties --file=/entrypoint-wildfly-cli/${BATCH_FILE}
        elif [ -f "${WILDFLY_HOME}/internal_cli/${BATCH_FILE}" ]; then
            echoInfo "execute internal jboss-batchfile \"${BATCH_FILE}\""
            ${JBOSS_CLI} -c --properties=env.properties --file=${WILDFLY_HOME}/internal_cli/${BATCH_FILE}
        fi
        if [ $? -eq 0 ]; then
            touch ${MOS_READY_PATH}/${BATCH_FILE}.completed
        else
            echoErr "JBoss-Batchfile \"${BATCH_FILE}\" can not be execute"
            ${JBOSS_CLI} -c ":shutdown"
            rm -f ${MOS_READY_PATH}/jboss_cli_block
            exit 125
        fi
    done
    echo "${LINE}"
    echoSuc "all cli-files successfully executed$([ "${SECONDS}" -gt "0" ] && echo " (${SECONDS}s)")"
    echoInfo "> restart wildfly"
    ${WILDFLY_HOME}/bin/jboss-cli.sh -c ":shutdown"
fi

rm -f ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/*
rm -f ${MOS_READY_PATH}/jboss_cli_block env.properties
exit 0
