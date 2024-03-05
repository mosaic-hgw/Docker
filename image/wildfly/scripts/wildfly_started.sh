#!/bin/bash

[ -f ${MOS_READY_PATH}/jboss_cli_block ] && exit 1
[[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]] && exit 1
exit 0
