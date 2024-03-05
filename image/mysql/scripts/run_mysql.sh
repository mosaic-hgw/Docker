#!/bin/bash

# get colors
source ${HOME}/colors.sh

MYSQL_LOGS="${ENTRY_LOGS}/mysql"
[ ! -d ${MYSQL_LOGS} ] && mkdir -p ${MYSQL_LOGS}; \

if [ ! -e ${ENTRY_MYSQL_DATADIR}/ibdata1 ]
then
  touch ${MOS_READY_PATH}/import_sqls_block
  echo "${LINE}"
  echoInfo "-initialize the database for the first start"
  mysqld --no-defaults --initialize-insecure --datadir=${ENTRY_MYSQL_DATADIR}; \
  echoInfo "-start database for set root-user"
  mysqld_safe --defaults-file=${ENTRY_MYSQL_MY_CNF} --skip-networking --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --datadir=${ENTRY_MYSQL_DATADIR} > ${MYSQL_LOGS}/stdout.log &
  while ! mysqladmin --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock ping &>/dev/null; do sleep 1; done
  echoInfo "-set root-user with password"
  mysql -uroot --skip-password --protocol=socket --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock -e "\
    ALTER USER \"root\"@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\"; \
    CREATE USER \"root\"@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\"; \
    GRANT ALL ON *.* TO \"root\"@\"%\" WITH GRANT OPTION; \
  "
  echoInfo "-turn off mysql-server"
  echo -e "[client]\\nuser=root\\npassword=${MYSQL_ROOT_PASSWORD}\\n" > ${MYSQL_HOME}/.my.cnf
  mysqladmin --defaults-file=${MYSQL_HOME}/.my.cnf --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock shutdown
  rm -f ${MYSQL_HOME}/.my.cnf
fi

echo "${LINE}"
${MYSQL_HOME}/import_sqls.sh
EXIT_CODE=$?
if [ ${EXIT_CODE} -ne 0 ]; then
  echoErr "import_sqls.sh is interrupted"
    exit ${EXIT_CODE}
fi

echo "${LINE}"
echoInfo "start mysql-server"
echoDeb "mysqld --defaults-file=${ENTRY_MYSQL_MY_CNF} --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --datadir=${ENTRY_MYSQL_DATADIR} ${MYSQL_OPTS}"
mysqld --defaults-file=${ENTRY_MYSQL_MY_CNF} --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --datadir=${ENTRY_MYSQL_DATADIR} ${MYSQL_OPTS} | tee -a ${MYSQL_LOGS}/stdout.log