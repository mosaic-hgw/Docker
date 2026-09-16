#!/bin/bash

# get commons
source ${HOME}/commons.sh

FIND_FILTER="-name '*.jmx'"
#>available-env< JMETER_ONLY_TESTFILES
if [ -n "${JMETER_ONLY_TESTFILES}" ]; then
  FIND_FILTER="$(echo "$JMETER_ONLY_TESTFILES" | sed -z '$ s/\n$//' | tr ',; ' '\n' | sed 's/^/-o -name /' | tr '\n' ' ' | sed 's/^-o //' | sed 's/-o -name -o -name /-o -name /g')"
fi

# get test-files
TEST_FILES="$(eval "find ${ENTRY_JMETER_TESTS} -type f ${FIND_FILTER}" | sort)"
if [ "${TEST_FILES}" = '' ]; then
  echoErr "${ERROR} nothing to do. no test-plan found."
  exit 1
else
  for TEST_FILE in ${TEST_FILES}; do
    echoInfo "- $(basename ${TEST_FILE})"
  done
fi

# get property-files
PROPERTIES="$(find "${ENTRY_JMETER_PROPERTIES}" -maxdepth 1 -type f ! -name 'system.properties' ! -name 'jmeter.properties' -exec basename {} \; | \
  sort | xargs -0 -r -n1 -I{} printf -- '-q %s ' "{}")"
[[ -z "$PROPERTIES" || "$PROPERTIES" == '-q ' ]] && PROPERTIES=''

# overwrite (jmeter|system).properties if exist
for PROP_FILE in 'jmeter.properties' 'system.properties'; do
  SRC="${ENTRY_JMETER_PROPERTIES}/${PROP_FILE}"
  DST="${JMETER_HOME}/bin/${PROP_FILE}"
  BAK="${DST}.bak"
  if [ -L "$DST" ]; then
    echoWarn "$DST comes from mount or link. This file remains untouched."
  elif [ -f "$SRC" ]; then
    [ -f "$DST" ] && [ ! -f "$BAK" ] && mv "$DST" "$BAK"
    cp -f "$SRC" "$DST"
  elif [ -f "$BAK" ]; then
    mv -f "$BAK" "$DST"
  fi
done

echo "${LINE}"

# logging
if [ ! -e "${ENTRY_JMETER_LOGS}" ]; then
  ENTRY_JMETER_LOGS="${ENTRY_LOGS}/jmeter"
  [ ! -e "${ENTRY_JMETER_LOGS}" ] && mkdir "${ENTRY_JMETER_LOGS}"
fi

#>deprecated-env< JMETER_LOG_TO_FILE JMETER_LOG_TO
if [ -z "${JMETER_LOG_TO}" ]; then
  JMETER_LOG_TO='CONSOLE'
  if [[ ${JMETER_LOG_TO_FILE,,} =~ ^(true|yes|on|1)$ ]]; then
    JMETER_LOG_TO='CONSOLE;FILE'
  fi
fi

#>available-env< JMETER_LOG_TO CONSOLE
if [[ ! ${JMETER_LOG_TO,,} =~ console ]]; then
  sed -i 's|<AppenderRef ref="console" />|<!-- <AppenderRef ref="console" /> -->|' "${JMETER_HOME}/bin/log4j2.xml"
fi
if [[ ! ${JMETER_LOG_TO,,} =~ file ]]; then
  sed -i 's|<AppenderRef ref="jmeter-log" />|<!-- <AppenderRef ref="jmeter-log" /> -->|' "${JMETER_HOME}/bin/log4j2.xml"
fi

#>available-env< JMETER_LOG_LEVEL INFO
LOG_LEVEL='-LINFO'
if [[ ${JMETER_LOG_LEVEL^^} =~ (TRACE|DEBUG|INFO|WARN|ERROR|OFF) ]]; then
  LOG_LEVEL="-L${JMETER_LOG_LEVEL^^}"
fi

#>available-env< JMETER_REPORT_TYPE none
case "${JMETER_REPORT_TYPE,,}" in
  none | '')    REPORT_TYPE='';;
  csv)          REPORT_TYPE='csv';;
  xml | junit)  REPORT_TYPE='xml';;
  ?*) echoErr "${ERROR} given JMETER_REPORT_TYPE is not valid. use one of: none, csv, xml or junit"; exit 1;;
esac

# start test-files separately
for TEST_FILE in ${TEST_FILES}; do
  echo "${LINE}"
  echoSuc "${INFO} --- start jmeter ${TEST_FILE} --------------------------------"

  # configure report
  REPORTING=""
  REPORT_FILE="${ENTRY_JMETER_LOGS}/$(basename "${TEST_FILE}")_result"
  [ -n "${REPORT_TYPE}" ] && \
    REPORTING="-l ${REPORT_FILE}.jtl -Jjmeter.save.saveservice.output_format=${REPORT_TYPE}"

  # start jmeter with test
  CMD=(jmeter -n -t "${TEST_FILE}" ${REPORTING} ${PROPERTIES} ${LOG_LEVEL} -Jprometheus.ip=0.0.0.0)
  echoDeb "${CMD[*]}"
  export JAVA_VERSION=21
  "${CMD[@]}"

  # convert xml-report to junit-xml
  if [ "${JMETER_REPORT_TYPE,,}" = 'junit' ]; then
    CMD=(xsltproc --stringparam jmxFile "$(basename "${TEST_FILE}")" "${JMETER_HOME}/jmeter-results-to-junit.xsl" "${REPORT_FILE}.jtl")
    echoDeb "${CMD[*]} > ${REPORT_FILE}.xml"
    "${CMD[@]}" > "${REPORT_FILE}.xml"
  fi

  # search for errors
  STDOUT_LOG_FILE="${MOS_TEMP_PATH}/summary.log"
  while read LINE ; do
    if echo ${LINE} | grep -qE "summary =[^E]+Err: +[1-9]+" ; then
      echoErr "${ERROR} --- stoppt jmeter ${TEST_FILE} with errors ------------------"
      exit 1
    fi
  done < ${STDOUT_LOG_FILE}
  echoSuc "${INFO} --- finished jmeter ${TEST_FILE} -----------------------------"

done