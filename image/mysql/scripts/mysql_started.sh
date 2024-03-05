#!/bin/bash

[ -f "${MOS_READY_PATH}/import_sqls_block" ] && exit 1
${MYSQL_HOME}/healthcheck_mysql.sh > /dev/null 2>&1 || exit 1
