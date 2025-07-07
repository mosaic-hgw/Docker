#!/bin/bash

EXIT_CODE=0
echo -e "[client]\\nprotocol=socket\\nsocket=${ENTRY_MYSQL_SOCKET}/mysql.sock\\nuser=root\\npassword=${MYSQL_ROOT_PASSWORD}\\n" > ${MYSQL_HOME}/.ping.cnf

if [ ! -e ${ENTRY_MYSQL_DATADIR}/ibdata1 ]
then
  echo "mysql is not initialized"
  EXIT_CODE=1
elif [ ! -e ${ENTRY_MYSQL_SOCKET}/mysql.sock ]
then
  echo "mysqld is not started"
  EXIT_CODE=1
elif ! (mysqladmin --defaults-file=${MYSQL_HOME}/.ping.cnf ping --silent > /dev/null)
then
  echo "mysqld is not alive"
  EXIT_CODE=1
fi
echo "mysqld is running"

rm -f ${MYSQL_HOME}/.ping.cnf
exit ${EXIT_CODE}