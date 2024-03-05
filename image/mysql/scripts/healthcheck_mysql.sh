#!/bin/bash

if [ ! -e ${ENTRY_MYSQL_DATADIR}/ibdata1 ]
then
  echo "mysql is not initialized"
  exit 1
elif [ ! -e ${ENTRY_MYSQL_SOCKET}/mysql.sock ]
then
  echo "mysqld is not started"
  exit 1
elif ! (mysqladmin --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock ping --silent > /dev/null)
then
  echo "mysqld is not alive"
  exit 1
fi
echo "mysqld is running"
