#!/bin/bash

# get colors
source ${HOME}/colors.sh

MYSQL_LOGS="${ENTRY_LOGS}/mysql"

SQL_FILES=$(comm -23 <(ls ${ENTRY_MYSQL_SQLS} | sort | grep .sql 2> /dev/null | grep -v .completed) <(ls ${MOS_READY_PATH} 2> /dev/null | grep .completed | sed "s/\.completed$//"))
echoInfo "$(echo ${SQL_FILES} | wc -w) sql-file(s) found to execute in mysql-server"
echoInfo "${SQL_FILES}" | tr "\\n" "," | sed "s/,$//"
echo

if [ $(echo ${SQL_FILES} | wc -w) -gt 0 ]
then
  touch ${MOS_READY_PATH}/import_sqls_block
  echo -e "[client]\\nuser=root\\npassword=${MYSQL_ROOT_PASSWORD}\\n" > ${MYSQL_HOME}/.my.cnf
\
  mysqld_safe --defaults-file=${ENTRY_MYSQL_MY_CNF} --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --skip-networking --datadir=${ENTRY_MYSQL_DATADIR} > ${MYSQL_LOGS}/stdout.log &
  while ! mysqladmin --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock ping &>/dev/null; do sleep 1; done
\
  for SQL_FILE in ${SQL_FILES}
  do
    if [ -f "${ENTRY_MYSQL_SQLS}/${SQL_FILE}" ]
    then
      echoInfo "execute sql-file \"${SQL_FILE}\""
      mysql --defaults-file=${MYSQL_HOME}/.my.cnf --protocol=socket --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock < ${ENTRY_MYSQL_SQLS}/${SQL_FILE}
      if [ $? -eq 0 ]
      then
        touch ${MOS_READY_PATH}/${SQL_FILE}.completed
      else
        echoErr "sql-file \"${SQL_FILE}\" can not be execute"
        rm -f ${MOS_READY_PATH}/import_sqls_block ${MYSQL_HOME}/.my.cnf
        exit 200
      fi
    fi
  done
\
  mysqladmin --defaults-file=${MYSQL_HOME}/.my.cnf --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock shutdown
fi
\
rm -f ${MOS_READY_PATH}/import_sqls_block ${MYSQL_HOME}/.my.cnf
exit 0
