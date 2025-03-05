#!/bin/bash

# get commons
source ${HOME}/commons.sh

if [ -f "${ENTRY_WILDFLY_SERVER_KEYSTORE}" ]; then
    echo "${LINE}"
    echoInfo "found server-keystore at ${ENTRY_WILDFLY_SERVER_KEYSTORE}"
    if [ -n "${WF_SERVER_KEYSTORE_PASSWORD}" ]; then
        KEYSTORE_DUMP=$(keytool -list -keystore "${ENTRY_WILDFLY_SERVER_KEYSTORE}" -storepass "${WF_SERVER_KEYSTORE_PASSWORD}" -rfc 2>&1)
        if echo "$KEYSTORE_DUMP" | grep -q "keytool error:"; then
            echoErr "$KEYSTORE_DUMP"
            exit 125
        elif [ -n "${WF_SERVER_KEYSTORE_ALIAS}" ]; then
            if echo "$KEYSTORE_DUMP" | grep -qE "^Alias name: ${WF_SERVER_KEYSTORE_ALIAS}$"; then
                echoSuc "alias for certificate found, using '${WF_SERVER_KEYSTORE_ALIAS}'"
            else
                echoErr "given certificate alias '${WF_SERVER_KEYSTORE_ALIAS}' not found"
                exit 125
            fi
        elif [ "$(echo "$KEYSTORE_DUMP" | grep "Your keystore contains" | sed -r 's/.+ ([0-9]+) .+/\1/')" -eq "1" ]; then
            WF_SERVER_KEYSTORE_ALIAS=$(echo "$KEYSTORE_DUMP" | grep "Alias name:" | sed -r 's/Alias name: ?(.+)/\1/')
            echoSuc "one certificate found, using alias '${WF_SERVER_KEYSTORE_ALIAS}'"
            sed -i "s/\${env.WF_SERVER_KEYSTORE_ALIAS}/${WF_SERVER_KEYSTORE_ALIAS}/" "${WILDFLY_HOME}/internal_cli/configure_wf_keystore.cli.disabled"
        else
            echoErr "more than one certificate found, you must enter an existing alias, use env-variable WF_SERVER_KEYSTORE_ALIAS"
            exit 125
        fi
        ln -s "${ENTRY_WILDFLY_SERVER_KEYSTORE}" "${WILDFLY_HOME}/standalone/configuration/serverKeystore.jks"
        mv "${WILDFLY_HOME}/internal_cli/configure_wf_keystore.cli.disabled" "${WILDFLY_HOME}/internal_cli/configure_wf_keystore.cli"
    else
        echoWarn "no password set, server-keystore is ignored"
    fi
fi

exit 0
