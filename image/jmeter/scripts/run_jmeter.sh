#!/bin/bash

echo -e "\n${EPOCHSECONDS}" >> ${JMETER_LOGS}/meminfo.log
cat /proc/meminfo >> ${JMETER_LOGS}/meminfo.log
echo -e "\n${EPOCHSECONDS}" >> ${JMETER_LOGS}/cpuinfo.log
lscpu >> ${JMETER_LOGS}/cpuinfo.log

# get test- and property-files
TEST_FILES=$(ls -d ${ENTRY_JMETER_TESTS}/*.jmx 2> /dev/null | sort)
PROPERTIES=$(ls -d ${ENTRY_JMETER_PROPERTIES}/*.* 2> /dev/null | sort)
[ -z "${TEST_FILES}" ] || TEST_FILES="-t ${TEST_FILES}"
[ -z "${PROPERTIES}" ] || PROPERTIES="-q ${PROPERTIES}"

echo "${LINE}"
if [ -z "${TEST_FILES}" ]; then
  echo "nothing to do. no test-plan found."
  exit 1
fi

# logging
echo "" > /stdout.log
LOGGING=""
[ -z "${JMETER_LOG_LEVEL}" ] || LOGGING="-L${JMETER_LOG_LEVEL}"
if [ "${JMETER_LOG_TO_FILE^^}" = "TRUE" ]; then
  LOGGING+=" -j ${JMETER_LOGS}/jmeter.log | tee /stdout.log"
else
  LOGGING+=" -j /dev/null"
fi

# start jmeter with tests
CMD="jmeter -n ${TEST_FILES} ${PROPERTIES} ${LOGGING}"
echo ${CMD}
eval ${CMD}
echo "${LINE}"

echo -e "\n${EPOCHSECONDS}" >> ${JMETER_LOGS}/meminfo.log
cat /proc/meminfo >> ${JMETER_LOGS}/meminfo.log

# search for errors
while read LINE ; do
  if echo ${LINE} | grep -qE "summary =[^E]+Err: +[1-9]+" ; then
    exit 1
  fi
done < /stdout.log
