#!/bin/bash

# get colors
source ${HOME}/colors.sh

if [ ! -f "${MOS_READY_PATH}/admin.created" ]; then
    echo "${LINE}"
    if [ -z "${WF_NO_ADMIN}" ]; then
        echoSuc "You can configure this WildFly-Server using:"
        echoSuc "  Username: ${WF_ADMIN_USER}"
        if [ -z "${WF_ADMIN_PASS}" ]; then
            WF_ADMIN_PASS=$(tr -cd "[:alnum:]" < /dev/urandom | head -c20)
            echoSuc "  Password: ${WF_ADMIN_PASS}"
            echoSuc "The password is displayed here only this once."
        else
            echoSuc "  Password: ***known***"
        fi
        ${WILDFLY_HOME}/bin/add-user.sh ${WF_ADMIN_USER} ${WF_ADMIN_PASS}
    else
        echoInfo "You can NOT configure this WildFly-Server"
        echoInfo "because no admin-user was created."
    fi
    touch ${MOS_READY_PATH}/admin.created
fi
