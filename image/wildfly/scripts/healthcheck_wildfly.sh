#!/bin/bash

[ -f "${MOS_READY_PATH}/jboss_cli_block" ] && exit 1

# check is wildfly running
${WILDFLY_HOME}/wildfly_started.sh || (echo "wildfly not running" && exit 1)

# if set WF_HEALTHCHECK_URLS via env-variable, then check this for request-code 200
if [ -n "$WF_HEALTHCHECK_URLS" ]
then
    echo "using healthcheck-urls"
    while read DEPLOYMENT_URL
    do
        [ -z "${DEPLOYMENT_URL}" ] && continue
        URL_STATE=$(curl -sLNIX GET "${DEPLOYMENT_URL}" | grep -E "HTTP/[0-9\.]+ [0-9]{3}" | tail -n1)
        echo " > ${DEPLOYMENT_URL}: ${URL_STATE}"
        if [[ $URL_STATE != *"200"* ]]
        then
            echo "url '${DEPLOYMENT_URL}' has returned '${URL_STATE//[$'\t\r\n']}', expected 200"
            exit 1
        fi
    done < <(echo "$WF_HEALTHCHECK_URLS" | sed "s/ /\n/g")
fi

# if set WF_ADMIN_PASS, then check deployments via management-tool
if [ -n "$WF_ADMIN_PASS" ]
then
    echo "using wildfly-password"
    MGNT_URL="http://${WF_ADMIN_USER}:${WF_ADMIN_PASS}@localhost:9990/management"
    DEPLOYMENTS=$(curl -sk --digest "${MGNT_URL}" | grep -oE '"deployment" ?: ?(null|\{[^}]*\}),' | sed -r 's/([": \{\}]|deployment|null)//g;s/,/\n/g;s/\n$//')
    while read DEPLOYMENT
    do
        DEPLOYMENT_STATE=$(curl -sk --digest "${MGNT_URL}/deployment/${DEPLOYMENT}?operation=attribute&name=status")
        echo " > ${DEPLOYMENT}: ${DEPLOYMENT_STATE}"
        if [[ $DEPLOYMENT_STATE == *"FAILED"* ]]
        then
            echo "deployment ${DEPLOYMENT} failed"
            exit 1
        fi
    done < <(echo "$DEPLOYMENTS")
fi

# if both are not set, use as fallback-variant the jboss-cli to check deployment-states
if [ -z "$WF_ADMIN_PASS" ] && [ -z "$WF_HEALTHCHECK_URLS" ]
then
    echo "using fallback-variant"
    DEPLOYMENTS=$($JBOSS_CLI -c "deployment-info" | awk '{if (NR!=1) {print $1,$NF}}')
    while read DEPLOYMENT
    do
        DEPLOYMENT_NAME=$(echo "$DEPLOYMENT" | awk '{print $1}')
        DEPLOYMENT_STATE=$(echo "$DEPLOYMENT" | awk '{print $2}')
        echo " > ${DEPLOYMENT_NAME}: ${DEPLOYMENT_STATE}"
        if [[ ${DEPLOYMENT_STATE} == *"FAILED"* ]]
        then
            echo "deployment ${DEPLOYMENT_NAME} failed"
            exit 1
        fi
    done < <(echo "$DEPLOYMENTS")
fi

exit 0
