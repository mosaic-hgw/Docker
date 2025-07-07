#!/bin/bash

# get commons
source ${HOME}/commons.sh

#>available-env< MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD="${TTP_MYSQL_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}"
#>available-env< MYSQL_OPTS
OPTS="${TTP_MYSQL_OPTS:-${MYSQL_OPTS}}"
#>available-env< MYSQL_UPDATE_SCANNER_ENABLED false
MYSQL_UPDATE_SCANNER_ENABLED="${TTP_MYSQL_UPDATE_SCANNER_ENABLED:-${MYSQL_UPDATE_SCANNER_ENABLED}}"
[[ ${MYSQL_UPDATE_SCANNER_ENABLED,,} =~ ^(true|yes|on|1)$ ]] && MYSQL_UPDATE_SCANNER_ENABLED=true || MYSQL_UPDATE_SCANNER_ENABLED=false
#>available-env< MYSQL_UPDATE_SCANNER_INTERVAL 30
MYSQL_UPDATE_SCANNER_INTERVAL="${TTP_MYSQL_UPDATE_SCANNER_INTERVAL:-${MYSQL_UPDATE_SCANNER_INTERVAL:-30}}"
[[ ! ${MYSQL_UPDATE_SCANNER_INTERVAL} =~ ^[0-9]+$ ]] && MYSQL_UPDATE_SCANNER_INTERVAL=30
#>available-env< MYSQL_LOG_TO CONSOLE
MYSQL_LOG_TO="${MYSQL_LOG_TO:-${TTP_MYSQL_LOG_TO}}"

INITIALIZE_DB=false
[ ! -e ${ENTRY_MYSQL_DATADIR}/ibdata1 ] && INITIALIZE_DB=true
[ ! -d "${ENTRY_MYSQL_UPDATE_SQLS}/done" ] && mkdir "${ENTRY_MYSQL_UPDATE_SQLS}/done"

MY_TEMP_CONF="${MYSQL_HOME}/my_temp.cnf"
MY_COPY_CONF="${MYSQL_HOME}/my_copy.cnf"
[ -e ${MY_COPY_CONF} ] && rm ${MY_COPY_CONF}
cp ${ENTRY_MYSQL_MY_CNF} ${MY_COPY_CONF}

count_init_sqls() {
  ls ${ENTRY_MYSQL_SQLS}/*.sql 2>/dev/null | wc -w
}
count_update_sqls() {
  ls ${ENTRY_MYSQL_UPDATE_SQLS}/*.sql 2>/dev/null | wc -w
}
create_temp_conf() {
  touch ${MOS_READY_PATH}/import_sqls_block
  echo -e "[client]\\nprotocol=socket\\nsocket=${ENTRY_MYSQL_SOCKET}/mysql.sock\\nuser=root\\npassword=${MYSQL_ROOT_PASSWORD}\\n" >> ${MY_TEMP_CONF}
}
remove_temp_conf() {
  rm -f ${MOS_READY_PATH}/import_sqls_block ${MY_TEMP_CONF}
}
test_import_block() {
  [ -e ${MOS_READY_PATH}/import_sqls_block ]
}

import_sqls() {
  local SQL_FILES="$1"
  local MOVE_DONE=${2:-false}
  local EXIT_ON_FAIL=${3:-true}

  if [ $(echo ${SQL_FILES} | wc -w) -gt 0 ] && test_import_block; then
    for SQL_FILE in ${SQL_FILES}; do
      if [ -f "${SQL_FILE}" ]; then
        echoInfo "- execute ${SQL_FILE}"
        mysql --defaults-file="${MY_TEMP_CONF}" < "${SQL_FILE}"
        if [ $? -eq 0 ]; then
          touch "${MOS_READY_PATH}/$(basename "${SQL_FILE}").imported"
          if ${MOVE_DONE}; then
            mv "${SQL_FILE}" "$(dirname "${SQL_FILE}")/done/$(basename "${SQL_FILE}")"
          fi
        else
          echoErr "sql-file \"${SQL_FILE}\" can not be execute"
          ${EXIT_ON_FAIL} && exit 200
        fi
      fi
    done
  fi
}

sql_scanner() {
  while true; do
    sleep ${MYSQL_UPDATE_SCANNER_INTERVAL}
    if [ "$(count_update_sqls)" -gt 0 ] && ! test_import_block; then
      echoInfo "found new update-sqls ($(count_update_sqls))"
      create_temp_conf
      import_sqls "$(ls ${ENTRY_MYSQL_UPDATE_SQLS}/*.sql | sort)" true false
      remove_temp_conf
    fi
  done
}

#initialition and update
if [ "$(count_update_sqls)" -gt 0 ] || ${INITIALIZE_DB}; then
  echo "${LINE}"
  create_temp_conf

  if ${INITIALIZE_DB}; then
    echoInfo "initialize database"
    mysqld --defaults-file=${MY_COPY_CONF} --skip-log-bin --log-error=${MYSQL_HOME}/stdout.log --initialize-insecure --datadir=${ENTRY_MYSQL_DATADIR}
  fi

  echoInfo "start mysql-server"
  mysqld_safe --defaults-file=${MY_COPY_CONF} --skip-networking --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --datadir=${ENTRY_MYSQL_DATADIR} &
  echoInfo "wait until mysql-server is started"
  while ! mysqladmin --defaults-file=${MY_TEMP_CONF} ping &>/dev/null; do sleep 1; done

  if ${INITIALIZE_DB}; then
    echoInfo "set root-user with password"
    mysql --defaults-file=${MY_TEMP_CONF} --skip-password -e "\
      ALTER USER \"root\"@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\"; \
      CREATE USER \"root\"@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\"; \
      GRANT ALL ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;"

    echoInfo "import init-sqls ($(count_init_sqls))"
    if [ "$(count_init_sqls)" -gt 0 ]; then
      import_sqls "$(ls ${ENTRY_MYSQL_SQLS}/*.sql | sort)"
    fi
  fi

  echoInfo "import update-sqls ($(count_update_sqls))"
  if [ "$(count_update_sqls)" -gt 0 ]; then
    import_sqls "$(ls ${ENTRY_MYSQL_UPDATE_SQLS}/*.sql | sort)" true
  fi

  echoInfo "turn off mysql-server"
  mysqladmin --defaults-file=${MY_TEMP_CONF} shutdown
  remove_temp_conf
fi

# start scanner
if ${MYSQL_UPDATE_SCANNER_ENABLED}; then
  echo "${LINE}"
  echoInfo "Starting scanner for new update-sqls (interval ${MYSQL_UPDATE_SCANNER_INTERVAL}s)"
  sql_scanner &
fi

# start mysql-server
echo "${LINE}"
MYSQL_CMD="mysqld --defaults-file=${MY_COPY_CONF} --socket=${ENTRY_MYSQL_SOCKET}/mysql.sock --datadir=${ENTRY_MYSQL_DATADIR}"
if [[ ${MYSQL_LOG_TO^^} == *"CONSOLE"* ]] && [[ ${MYSQL_LOG_TO^^} == *"FILE"* ]]; then
  echoInfo "Starting MySQL-Server with logging to console and file"
  echoDeb "${MYSQL_CMD}"
  ${MYSQL_CMD} --log-error=${ENTRY_MYSQL_LOGS}/error.log --general-log=1 --general-log-file=${ENTRY_MYSQL_LOGS}/general.log ${OPTS} 2>&1 | tee -a "${ENTRY_MYSQL_LOGS}/stdout.log"
elif [[ ${MYSQL_LOG_TO^^} = *"CONSOLE"* ]] && [[ ${MYSQL_LOG_TO^^} != *"FILE"* ]]; then
  echoInfo "Starting MySQL-Server with logging to console"
  echoDeb "${MYSQL_CMD}"
  ${MYSQL_CMD} --log-error=${MYSQL_HOME}/stdout.log --general-log=1 --general-log-file=${MYSQL_HOME}/stdout.log ${OPTS}
elif [[ ${MYSQL_LOG_TO^^} != *"CONSOLE"* ]] && [[ ${MYSQL_LOG_TO^^} == *"FILE"* ]]; then
  echoInfo "Starting MySQL-Server with logging to file"
  echoDeb "${MYSQL_CMD}"
  ${MYSQL_CMD} --log-error=${ENTRY_MYSQL_LOGS}/error.log --general-log=1 --general-log-file=${ENTRY_MYSQL_LOGS}/general.log ${OPTS} > "${ENTRY_MYSQL_LOGS}/stdout.log" 2>&1
else
  echoInfo "Starting MySQL-Server with no logging"
  echoDeb "${MYSQL_CMD}"
  ${MYSQL_CMD} --log-error=/dev/null --general-log=0 ${OPTS} > /dev/null 2>&1
fi

echoWarn "MySQL-Server is stopped"
