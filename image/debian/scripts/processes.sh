#!/bin/bash

#>available-env< MOS_INCLUDE_PROCESSES
#>available-env< MOS_EXCLUDE_PROCESSES
#>available-env< MOS_RUN_MODE service
#>available-env< MOS_SHUTDOWN_DELAY

# get commons
source "${HOME}/commons.sh"

# VARIABLES ############################################################################################################
VERSION_NUMBER='2025.1.0'
VERSION="\n Version ${VERSION_NUMBER} from 2025-03-25\n Maintained by Ronny Schuldt\n"
PROCESSES_FILE="${HOME}/mosaic_processes"
COLS=( \
  "name:10:Name" \
  "order:5:Order" \
  "type:7:Type" \
  "run_script:50:Run-Script" \
  "started_script:50:Started-Script" \
  "status:10:Status" \
  "pid:6:PID" \
  "ts_started:13:TS-Started" \
  "ts_ready:13:TS-Ready" \
  "ts_stopped:13:TS-Stopped" \
  "count_started:13:Count-Started" \
  "exit_code:9:Exit-Code" \
)
EXITCODE_TO_IGNORE_RESTART=250

# FUNCTIONS ############################################################################################################
add_process() {
  local name
  local order
  local type
  local run_script
  local started_script

  IFS=':' read -r name order type run_script started_script <<< "${1}"
  store_process "name:${name}" "order:${order}" "type:${type}" "run_script:${run_script}" "started_script:${started_script}" "status:added"
}

get_process() {
  local name="${1}"
  local key_value
  local i_key
  local i_width
  local i_label
  local pos=1
  local line

  line="$(sed '1d;/^'${name}' /!d' "${PROCESSES_FILE}")"
  [ -z "${line}" ] && return
  for key_value in "${COLS[@]}"; do
    IFS=':' read -r i_key i_width i_label <<< "${key_value}"
    echo "${i_key}:$(echo "${line}" | cut -b ${pos}-$(( pos+i_width-1 )) | xargs)"
    pos=$(( pos+i_width+1 ))
  done
}

get_process_names() {
  awk 'NR > 1 {print $1}' "${PROCESSES_FILE}"
}

list_all_processes() {
  cat "${PROCESSES_FILE}"
}

store_process() {
  local key_value
  local key_value2
  local i_key
  local i_width
  local i_label
  local i_value
  local name
  local key
  local value
  local widths=""
  local values=""

  for key_value in "$@"; do
    IFS=':' read -r i_key i_value <<< "${key_value}"
    if [ "${i_key}" = "name" ]; then
      name="${i_value}"
      break
    fi
  done

  old_line="$(get_process "${name}")"

  for key_value in "${COLS[@]}"; do
    IFS=':' read -r key i_width i_label <<< "${key_value}"
    widths+="%-${i_width}s "
    value=''
    for key_value2 in ${old_line}; do
      IFS=':' read -r i_key i_value <<< "${key_value2}"
      [ "${i_key}" = "${key}" ] && value="${i_value}" && break
    done
    for key_value2 in "$@"; do
      IFS=':' read -r i_key i_value <<< "${key_value2}"
      [ "${i_key}" = "${key}" ] && value="${i_value}" && break
    done
    values+="'${value}' "
  done

  if [ -z "${old_line}" ]; then
    eval "printf '${widths}\n' ${values}" >> "${PROCESSES_FILE}"
  else
    sed -i "1!{/^${name} / s:.*:$(eval "printf '${widths}\n' ${values}"):}" "${PROCESSES_FILE}"
  fi
}

create_process_file() {
  local key_value
  local i_key
  local i_width
  local i_label
  local widths=""
  local labels=""
  for key_value in "${COLS[@]}"; do
    IFS=':' read -r i_key i_width i_label <<< "${key_value}"
    widths+="%-${i_width}s "
    labels+="'${i_label}' "
  done
  eval "printf '${widths}\n' ${labels} > '${PROCESSES_FILE}'"
}

start_all_processes() {
  SECONDS=0   # bash-internal variable
  local names
  local name
  local status
  local started=0
  local count
  local process_bilance=""

  # start all processes
  names="$(awk 'NR > 1 {print $1" "$2}' "${PROCESSES_FILE}" | sort -k2,2n | cut -d ' ' -f 1)"
  count=$(echo "${names}" | wc -w)
  for name in ${names}; do
    if ! check_running_processes; then
      echoErr "one service is finished. abort all start processes."
      stop_all_processes
      return 1
    fi

    status=''
    if [ -n "${MOS_INCLUDE_PROCESSES}" ] && ! echo "${name}" | grep -qE "${MOS_INCLUDE_PROCESSES}"; then
      echoWarn "ignored ${name} by filter ${MOS_INCLUDE_PROCESSES}"
      status="ignored"
    elif [ -n "${MOS_EXCLUDE_PROCESSES}" ] && echo "${name}" | grep -qE "${MOS_EXCLUDE_PROCESSES}"; then
      echoWarn "exclude ${name} by filter ${MOS_EXCLUDE_PROCESSES}"
      status="excluded"
    else
      start_process "${name}"
      exit_code=$?
      if [ ${exit_code} -gt 0 ] ; then
        echoErr "cannot start process ${name}. abort all processes."
        stop_all_processes
        return ${exit_code}
      fi
      started=$((started+1))
      continue
    fi
    store_process "name:${name}" "status:${status}"
  done
  [ "${started}" -ne "${count}" ] && process_bilance="${started}/${count}"
  [ -n "${process_bilance}" ] && [ "${SECONDS}" -gt "0" ] && process_bilance+=" in "
  [ "${SECONDS}" -gt "0" ] && process_bilance+="${SECONDS}s"
  [ -n "${process_bilance}" ] && process_bilance="(${process_bilance})"
  echoSuc "all processes started ${process_bilance}"

  # stop after x seconds if set delay
  if [ -n "${MOS_SHUTDOWN_DELAY}" ]; then
    SECONDS=0   # bash-internal variable
    echoWarn "shutdown all services in ${MOS_SHUTDOWN_DELAY}s"
  fi

  # monitoring processes
  while true; do

    if [ -n "${MOS_SHUTDOWN_DELAY}" ] && [ "${SECONDS}" -ge "${MOS_SHUTDOWN_DELAY}" ]; then
      echoWarn "shutdown all services because MOS_SHUTDOWN_DELAY is set"
      stop_all_processes
      exit_code=0
      break
    fi

    case "${MOS_RUN_MODE,,}" in
      action)
        [ -n "${MOS_SHUTDOWN_DELAY}" ] && sleep "${MOS_SHUTDOWN_DELAY}"
        stop_all_processes
        exit_code=0
        break
        ;;
      service)
        check_running_processes true
        if [ "$(count_pids)" -eq 0 ]; then
          break
        fi
        ;;
      cascade)
        if ! check_running_processes; then
          exit_code=$?
          stop_all_processes
          break
        fi
        ;;
      external)
        # do nothing
        ;;
      *)
        echoErr "Unknown run-mode."
        stop_all_processes
        exit_code=1
        break
        ;;
    esac
    sleep 5
  done

  return ${exit_code}
}

start_process() {
  local name="${1}"
  local key_value
  local i_key
  local i_value
  local type
  local run_script
  local started_script
  local pid
  local count_started
  local exit_code=0

  for key_value in $(get_process "${name}"); do
    IFS=':' read -r i_key i_value <<< "${key_value}"
    case "${i_key}" in
      type)           type="${i_value}";;
      run_script)     run_script="${i_value}";;
      started_script) started_script="${i_value}";;
      pid)            pid="${i_value}";;
      count_started)  count_started="${i_value}";;
   esac
  done

  if [ -n "${pid}" ] && [ -e /proc/${pid}/exe ]; then
    echoWarn "${name} already running"
    return 0
  fi

  case "${type,,}" in
    action)
      echoInfo "start action ${name}"
      echoDeb "${run_script} &"
      ${run_script} &
      pid=$!
      store_process "name:${name}" "pid:${pid}" "ts_started:$(date +%s%3N)" "count_started:$((count_started+1))" "status:started" &
      wait ${pid}
      exit_code=$?
      store_process "name:${name}" "pid:" "ts_stopped:$(date +%s%3N)" "exit_code:${exit_code}" "status:stopped"
      ;;
    service)
      if [ "x${started_script}" != "x" ]; then
        echoInfo "start service ${name} and wait for running with ${started_script}"
        echoDeb "${run_script} &"
        ${run_script} &
        pid=$!
        store_process "name:${name}" "pid:${pid}" "ts_started:$(date +%s%3N)" "count_started:$((count_started+1))" "status:started" &
        while ! ${started_script} ; do
          check_running_processes
          exit_code=$?
          [ ${exit_code} -gt 0 ] && break
          sleep 1
        done
        store_process "name:${name}" "ts_ready:$(date +%s%3N)" "status:ready" &
      else
        echoInfo "start service ${name}"
        echoDeb "${run_script} &"
        ${run_script} &
        pid=$!
        store_process "name:${name}" "pid:${pid}" "ts_started:$(date +%s%3N)" "count_started:$((count_started+1))" "status:ready" &
        exit_code=0 # ok
      fi
      ;;
    *)
      echoErr "Unknown process-type."
      exit_code=1
      ;;
  esac

  return ${exit_code}
}

check_running_processes() {
  local names
  local restart_service_on_stopped="${1:-false}"
  local key_value
  local i_key
  local i_value
  local name
  local type
  local pid
  local status
  local exit_code
  local exited=0

  names="$(awk 'NR > 1 {print $1}' "${PROCESSES_FILE}")"
  for name in ${names}; do
    pid=
    for key_value in $(get_process "${name}"); do
      IFS=':' read -r i_key i_value <<< "${key_value}"
      case "${i_key}" in
        type)           type="${i_value}";;
        pid)            pid="${i_value}";;
        status)         status="${i_value}";;
      esac
    done

    exit_code=
    if [ -n "${pid}" ] && [ ! -e /proc/${pid}/exe ]; then
      wait ${pid}
      exit_code=$?
    fi
    if [ "${exit_code}" = "${EXITCODE_TO_IGNORE_RESTART}" ]; then
      store_process "name:${name}" "pid:" "ts_stopped:$(date +%s%3N)" "exit_code:${exit_code}" "status:successful"
      echoSuc "${name} is successful stopped."
      continue
    elif [[ ${exit_code} =~ ^[0-9]+$ ]]; then
      store_process "name:${name}" "pid:" "ts_stopped:$(date +%s%3N)" "exit_code:${exit_code}" "status:stopped"
      echoErr "${name} is unexpected stopped (with exit-code ${exit_code})."
      exited=1
    fi
    if [ "${restart_service_on_stopped,,}" = "true" ] && [ "${status,,}" = "stopped" ] && [ "${type,,}" = "service" ]; then
      start_process "${name}"
      exited=0
    fi
  done
  return ${exited}
}

count_pids() {
  local names
  local name
  local key_value
  local i_key
  local pid
  local pid_count=0

  names="$(awk 'NR > 1 {print $1}' "${PROCESSES_FILE}")"
  for name in ${names}; do
    for key_value in $(get_process "${name}"); do
      IFS=':' read -r i_key pid <<< "${key_value}"
      if [ "${i_key}" = "pid" ] && [ -n "${pid}" ]; then
        pid_count=$((pid_count+1))
        continue
      fi
    done
  done
  echo ${pid_count}
}

stop_all_processes() {
  local names
  local name
  names="$(awk 'NR > 1 {print $1" "$2}' "${PROCESSES_FILE}" | sort -k2,2nr | cut -d ' ' -f 1)"
  for name in ${names}; do
    stop_process "${name}"
  done
}

stop_process() {
  local name="${1}"
  local key_value
  local i_key
  local pid

  for key_value in $(get_process "${name}"); do
    IFS=':' read -r i_key pid <<< "${key_value}"
    if [ "${i_key}" = "pid" ]; then
      if [ -n "${pid}" ] && [ -d /proc/${pid}/ ]; then
        echoWarn "send terminate-signal to ${name}."
        kill_processes_tree "${pid}" true 4
        store_process "name:${name}" "pid:" "ts_stopped:$(date +%s%3N)" "status:terminated"
      fi
      break
    fi
  done
}

kill_processes_tree() {
  local pid="${1}"
  local kill_self="${2:-false}"
  local to_wait="${3:-0}"
  local children
  local child
  [ -z "${pid}" ] && return
  if children="$(pgrep -P "${pid}")"; then
    for child in ${children}; do
      kill_processes_tree "${child}" true 0
    done
  fi
  if [[ "${kill_self}" == true ]] && sleep ${to_wait} && [ -d /proc/${pid}/ ]; then
    kill -TERM "${pid}"
  fi
}

restart_all_processes() {
  stop_all_processes
  start_all_processes
  return $?
}

restart_process() {
  local name="${1}"
  stop_process "${name}"
  start_process "${name}"
}

usage() {
  local default="${YELLOW}"
  MOS_NO_TIME=1 echoCol "${default}
 This script is used to help control MOSAIC processes. These must be registered for this. After
 registration the processes can then be started, monitored and terminated. The registration and
 any further status changes are written to the file '${HOME}/mosaic_processes'.
 ${VERSION}
 Usage:
 [${BLUE}VARIABLE${default}=${RED}<VALUE>${default} [...]] ${GREEN}./${SELF_NAME}${default} [OPTION [...]]

 Available ENV-Variables:
    ${BLUE}MOS_INCLUDE_PROCESSES${default}            This variable can contain a regular expression that includes one or
                                     more process-names to be start by name.
    ${BLUE}MOS_EXCLUDE_PROCESSES${default}            This variable does exactly the opposite. It excludes process-names
                                     that match the regular expression.
    ${BLUE}MOS_RUN_MODE${default}                     This variable can have 4 different values, whereby each value
                                     influences the running behaviour of the image differently:
                                     - ${RED}action${default} will wait until all action-run-scripts are successful
                                       finished and then also stop the service-run-scripts.
                                     - ${RED}service${default} (default) starts all run-scripts and tries to restart
                                       services if they quit.
                                     - ${RED}cascade${default} like ${RED}service${default} but also stops all other services as soon as a
                                       service ends.
                                     - ${RED}external${default} like ${RED}service${default} but does not restart an ended service nor does
                                       it stop the others.
    ${BLUE}MOS_SHUTDOWN_DELAY${default}               This variable defines the duration, in seconds, after which all
                                     services should be gracefully terminated.

 Single-Process-Options:
    ${BLUE}-a ${RED}<VALUES>${default} | ${BLUE}--add=${RED}<VALUES>${default}     This parameter is used to register a process and must have the format:
                                     ${RED}NAME:ORDER:TYPE:RUN:STARTED${default}, whereby the last segment is optional.
                                     - The value ${RED}NAME${default} is used to identify the process. The name can be used
                                       to filter processes and start or stop them individually.
                                     - ${RED}ORDER${default} determines the start order, whereby a larger value means a
                                       later start.
                                     - With ${RED}TYPE${default} the start type of the layer is defined, which can contain
                                       the characteristics ${RED}action${default} and ${RED}service${default}.
                                     - With the value ${RED}action${default} the process at ${RED}RUN${default} waits until it terminates
                                       by itself. Only then are following processes executed.
                                     - With the value ${RED}service${default} the process at ${RED}RUN${default} startes in the background.
                                     - If the optional value ${RED}STARTED${default} is specified, this is used to check
                                       whether the process has been started correctly in order to start
                                       following processes.
    ${BLUE}-g ${RED}<NAME>${default}   | ${BLUE}--get=${RED}<NAME>${default}       Gets details of process by given name. The details prints line by line
                                     and in format ${RED}key:value${default}.
    ${BLUE}-s ${RED}<NAME>${default}   | ${BLUE}--start=${RED}<NAME>${default}     Start an given process.
    ${BLUE}-t ${RED}<NAME>${default}   | ${BLUE}--terminate=${RED}<NAME>${default} Terminate an given process.
    ${BLUE}-r ${RED}<NAME>${default}   | ${BLUE}--restart=${RED}<NAME>${default}   Terminate and start an given process.

 Group-Process-Options:
    ${BLUE}-sa${default} | ${BLUE}--start-all${default}                Starts all registered processes.
    ${BLUE}-ta${default} | ${BLUE}--terminate-all${default}            Terminates all registered processes.
    ${BLUE}-ra${default} | ${BLUE}--restart-all${default}              Terminates all running processes and starts
                                     all registered processes.

 Other Options:
    ${BLUE}-n${default}  | ${BLUE}--get-names${default}                List all registered processes.
    ${BLUE}-l${default}  | ${BLUE}--list${default}                     Shows content of '${HOME}/mosaic_processes'.
    ${BLUE}-e${default}  | ${BLUE}--get-successful-exit-code${default} Returns the exit-code (${EXITCODE_TO_IGNORE_RESTART}) at which a service is not restarted.
    ${BLUE}-v${default}  | ${BLUE}--version${default}                  View current version and maintainer.
    ${BLUE}-vn${default} | ${BLUE}--version-number${default}           View only current version-number.
    ${BLUE}-h${default}  | ${BLUE}--help${default}                     View this information.${NC}
"
}

# START ################################################################################################################
if [[ $# -eq 0 ]]; then
  echoErr "Nothing to do."
  usage
  exit 1
fi

if [ ! -f "${PROCESSES_FILE}" ]; then
  create_process_file
fi

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -a   | --add)                      add_process "${2}";                    shift 2 ;;
    -a=* | --add=*)                    add_process "${1#*=}";                 shift 1 ;;
    -g   | --get)                      get_process "${2}";                    shift 2 ;;
    -g=* | --get=*)                    get_process "${1#*=}";                 shift 1 ;;
    -sa  | --start-all)                start_all_processes;                   exit $? ;;
    -s   | --start)                    start_process "${2}";                  shift 2 ;;
    -s=* | --start=*)                  start_process "${1#*=}";               shift 1 ;;
    -ta  | --terminate-all)            stop_all_processes;                    shift 1 ;;
    -t   | --terminate)                stop_process "${2}";                   shift 2 ;;
    -t=* | --terminate=*)              stop_process "${1#*=}";                shift 1 ;;
    -ra  | --restart-all)              restart_all_processes;                 exit $? ;;
    -r   | --restart)                  restart_process "${2}";                shift 2 ;;
    -r=* | --restart=*)                restart_process "${1#*=}";             shift 1 ;;
    -n   | --get-names)                get_process_names;                     shift 1 ;;
    -l   | --list)                     list_all_processes;                    shift 1 ;;
    -e   | --get-successful-exit-code) echo "${EXITCODE_TO_IGNORE_RESTART}";  exit 0  ;;
    -vn  | --version-number)           echo "${VERSION_NUMBER}";              exit 0  ;;
    -v   | --version)                  echoCol "${VERSION}";                  exit 0  ;;
    -h   | --help)                     usage;                                 exit 0  ;;
    *)                                 echoErr "Unknown option: ${1}";        exit 1  ;;
  esac
done
