#!/bin/bash

# get commons
source ${HOME}/commons.sh

SRC_DIR="${ENTRY_WILDFLY_DEPLOYS}"
DES_DIR="${WILDFLY_HOME}/standalone/deployments"

getDirData(){
    stat -c "%Y%s,%n" ${1}/* 2> /dev/null | sed "s#${1}/##"
}
safeCopy(){
    touch ${3}/${1}.skipdeploy
    cp -p ${2}/${1} ${3}/
}

# clear DES_DIR
rm -f ${DES_DIR}/*

while true; do
    # to compare get only files with extensions of .ear, .war and .skipdeploy
    SRC=($(getDirData ${SRC_DIR} | grep -E "(\.jar|\.ear|\.war|\.skipdeploy)$"))
    DES=($(getDirData ${DES_DIR} | grep -E "(\.jar|\.ear|\.war|\.skipdeploy)$"))

    # search and sync new and modified files
    if [ ${#SRC[@]} -gt 0 ]; then
        for SRC_ITEM in "${SRC[@]}"; do
            SRC_NAME=$(echo ${SRC_ITEM} | cut -d, -f2)
            for DES_ITEM in "${DES[@]}"; do
                DES_NAME=$(echo ${DES_ITEM} | cut -d, -f2)
                if [ "${SRC_NAME}" = "${DES_NAME}" ]; then
                    SRC_DATESIZE=$(echo ${SRC_ITEM} | cut -d, -f1)
                    DES_DATESIZE=$(echo ${DES_ITEM} | cut -d, -f1)
                    if [ ! "${SRC_DATESIZE}" = "${DES_DATESIZE}" ]; then
                        echoInfo "resynchronize file: ${SRC_NAME}"
                        safeCopy ${SRC_NAME} ${SRC_DIR} ${DES_DIR}
                    fi
                    continue 2
                fi
            done
            echoInfo "synchronize file: ${SRC_NAME}"
            safeCopy ${SRC_NAME} ${SRC_DIR} ${DES_DIR}
        done
    fi

    # search and sync removed files
    if [ ${#DES[@]} -gt 0 ]; then
        for DES_ITEM in "${DES[@]}"; do
            DES_NAME=$(echo ${DES_ITEM} | cut -d, -f2)
            for SRC_ITEM in "${SRC[@]}"; do
                SRC_NAME=$(echo ${SRC_ITEM} | cut -d, -f2)
                [ "${SRC_NAME}" = "${DES_NAME}" ] && continue 2
            done
            echoInfo "unsynchronize file: ${DES_NAME}"
            rm ${DES_DIR}/${DES_NAME}
        done
    fi

    # release deployments
    rm ${DES_DIR}/*.skipdeploy ${DES_DIR}/*.undeployed 2> /dev/null

    # wait
    sleep 5
done
