#!/bin/bash

# get commons
source ${HOME}/commons.sh

MY_TEMP_CONF="${MYSQL_HOME}/my_temp.cnf"
MYSQL_ROOT_PASSWORD="${TTP_MYSQL_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}"
echo -e "[client]\\nprotocol=socket\\nsocket=${ENTRY_MYSQL_SOCKET}/mysql.sock\\nuser=root\\npassword=${MYSQL_ROOT_PASSWORD}\\n" > ${MY_TEMP_CONF}
if mysqladmin --defaults-file=${MY_TEMP_CONF} ping &>/dev/null; then
  echoInfo "Stopping Mysql-Server"
  mysqladmin --defaults-file=${MY_TEMP_CONF} shutdown
fi
rm -f ${MY_TEMP_CONF}
