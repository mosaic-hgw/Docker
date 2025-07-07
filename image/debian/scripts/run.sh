#!/bin/bash

#>available-env< TZ Europe/Berlin
#>available-env< MOS_WAIT_FOR_PORTS host:port[:timeout]

# get commons
source ${HOME}/commons.sh

# show versions
echo -e "${LINE}\n\n  https://hub.docker.com/repository/docker/mosaicgreifswald\n\n${LINE}\n\n$(versions)\n\n${LINE}"

# test entrypoints write permissions
echoInfo "test write-permission in entrypoints"
entrypoints | awk '{print $3}' | grep -v '^$' | while read DIR; do
  if [ -w "$(realpath "${DIR}")" ]; then
    echoInfo "- ${DIR} -> ok $(mount | grep -q " $(realpath "${DIR}") " && echo "(volume/mount)")"
  elif mount | grep -q " ${DIR} "; then
    echoErr "- ${DIR} -> not permitted (volume/mount)"
  else
    echoWarn "- ${DIR} -> not permitted"
  fi
done
echo "${LINE}"

# test env-variables
echoInfo "check environment-variables"
ENV_ALL_FINE="y"
while read STATE VAR_OLD VAR_NEW; do if env | grep -q "^${VAR_OLD}="; then
  ENV_ALL_FINE="n"
  if [ "${STATE}" = "#>deprecated-env<" ]; then
    echoWarn "- WARNING You are using an obsolete variable that will be removed in one of the next versions: ${VAR_OLD}"
  elif [ "${STATE}" = "#>deleted-env<" ]; then
    echoErr "- ERROR You are using an old (ignored) variable: ${VAR_OLD}"
  fi
  [ "${VAR_NEW}x" != "x" ] && echoInfo "  -> Use instead: ${VAR_NEW}"
fi; done < <(find /entrypoint-* ${HOME} -maxdepth 4 -type f \( -iname '*.cli' -o -iname '*.env' -o -iname '*.sh' \) -exec grep -E "^#>de(preca|le)ted-env<" {} \; | sed 's/\r//')
[ "${ENV_ALL_FINE}" = "y" ] && echoSuc "environment-variables are fine."
echo "${LINE}"

# wait for ports
if [ -n "${MOS_WAIT_FOR_PORTS}" ]; then
  echoInfo "wait for ports found: ${MOS_WAIT_FOR_PORTS}"
  echo "${LINE}"
  default_timeout=300
  for wait_for in $(echo "${MOS_WAIT_FOR_PORTS}" | tr ',;' '\n' | awk -F: '{if(NF==2){$0=$0":'${default_timeout}'"}print}' | sort -t: -k3,3n | paste -sd' ' -); do
    IFS=':' read -r i_host i_port i_timeout <<< "${wait_for}"
    ./wait-for-it.sh ${i_host}:${i_port} -t ${i_timeout} & waiting_pids+=($!)
  done
  for waiting_pid in ${waiting_pids[@]}; do
    wait ${waiting_pid} || exit $?
  done
fi

# start all registered processes
${HOME}/processes.sh --start-all
