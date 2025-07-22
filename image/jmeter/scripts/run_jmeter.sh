#!/bin/bash

# get commons
source ${HOME}/commons.sh

FIND_FILTER=""
#>available-env< JMETER_ONLY_TESTFILES
if [ "x${JMETER_ONLY_TESTFILES}" != "x" ]; then
  FIND_FILTER="-name '${JMETER_ONLY_TESTFILES//,/"' -name '"}'"
fi

# get test- and property-files
#TEST_FILES=$(find ${ENTRY_JMETER_TESTS} -maxdepth 1 -type f -name "*.jmx" ${FIND_FILTER} -exec basename {} \; | sort | xargs -n 1 echo -t | tr '\n' ' ')
TEST_FILES="$(eval "find ${ENTRY_JMETER_TESTS} -maxdepth 1 -type f -name '*.jmx' ${FIND_FILTER}" | sort)"
PROPERTIES="$(find ${ENTRY_JMETER_PROPERTIES} -maxdepth 1 -type f -exec basename {} \; | sort | xargs -n 1 echo -p | tr '\n' ' ')"
[[ -z "$PROPERTIES" || "$PROPERTIES" == "-p " ]] && PROPERTIES=""

echo "${LINE}"
if [ "${TEST_FILES}" = "" ]; then
  echoErr "nothing to do. no test-plan found."
  exit 1
fi

# logging
if [ ! -e "${ENTRY_JMETER_LOGS}" ]; then
  ENTRY_JMETER_LOGS="${ENTRY_LOGS}/jmeter"
  [ ! -e "${ENTRY_JMETER_LOGS}" ] && mkdir "${ENTRY_JMETER_LOGS}"
fi

#>deprecated-env< JMETER_LOG_TO_FILE JMETER_LOG_TO
if [ -z "${JMETER_LOG_TO}" ]; then
  JMETER_LOG_TO="CONSOLE"
  if [[ ${JMETER_LOG_TO_FILE,,} =~ ^(true|yes|on|1)$ ]]; then
    JMETER_LOG_TO="CONSOLE;FILE"
  fi
fi

#>available-env< JMETER_LOG_TO CONSOLE
if [[ ! ${JMETER_LOG_TO,,} =~ console ]]; then
  sed -i 's|<AppenderRef ref="console" />|<!-- <AppenderRef ref="console" /> -->|' "${JMETER_HOME}/bin/log4j2.xml"
fi
if [[ ! ${JMETER_LOG_TO,,} =~ file ]]; then
  sed -i 's|<AppenderRef ref="jmeter-log" />|<!-- <AppenderRef ref="jmeter-log" /> -->|' "${JMETER_HOME}/bin/log4j2.xml"
fi

#>available-env< JMETER_LOG_PATTERN %d{HH:mm:ss.SSS} %p  %m%n
#>available-env< JMETER_LOG_LEVEL INFO
LOG_LEVEL="-LINFO"
if [[ ${JMETER_LOG_LEVEL^^} =~ (TRACE|DEBUG|INFO|WARN|ERROR|OFF) ]]; then
  LOG_LEVEL="-L${JMETER_LOG_LEVEL}"
fi

# start test-files separately
for TEST_FILE in ${TEST_FILES}; do

  # start jmeter with test
  CMD="jmeter -n -t ${TEST_FILE}${PROPERTIES} ${LOG_LEVEL} -Jprometheus.ip=0.0.0.0"
  echoDeb "${CMD}"
  eval "${CMD}"
  echo "${LINE}"

  # search for errors
  STDOUT_LOG_FILE="${MOS_TEMP_PATH}/summary.log"
  while read LINE ; do
    if echo ${LINE} | grep -qE "summary =[^E]+Err: +[1-9]+" ; then
      exit 1
    fi
  done < ${STDOUT_LOG_FILE}
  echo "${LINE}"

done