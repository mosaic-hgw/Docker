#!/bin/bash

# get colors
source ${HOME}/colors.sh
HEADER="${NC}${UNDERLINE}${WHITE}"

# get all known env-variables
declare -A CURRENT_ENVS
declare -A AVAILABLE_ENVS
declare -A DEPRECATED_ENVS
declare -A DELETED_ENVS
declare ALL_ENVS=()

while IFS='=' read -r -d '' ENV_NAME VALUE; do
  CURRENT_ENVS[${ENV_NAME}]="${VALUE}"
  ALL_ENVS+=(${ENV_NAME})
done < <(env -0)

while read -r STATE ENV_NAME VALUE_OR_OLDKEY; do
  case ${STATE} in
    "#>available-env<")  AVAILABLE_ENVS[${ENV_NAME}]="${VALUE_OR_OLDKEY}";;
    "#>deprecated-env<") DEPRECATED_ENVS[${ENV_NAME}]="${VALUE_OR_OLDKEY}";;
    "#>deleted-env<")    DELETED_ENVS[${ENV_NAME}]="${VALUE_OR_OLDKEY}";;
  esac
  ALL_ENVS+=(${ENV_NAME})
done < <(find /entrypoint-* ${HOME} -maxdepth 4 -type f \( -iname '*.cli' -o -iname '*.env' -o -iname '*.sh' \) -exec grep -E "^#>(.+)-env<" {} \; | sed 's/\r//')

# sort ALL_ENVS
IFS=$'\n' ALL_ENVS=($(sort -u <<<"${ALL_ENVS[*]}"))
unset IFS
COL1=0 COL2=40 COL3=40 COL4=20 VCOL2=40 VCOL3=40
[ "${1}" = "--dont-cut-values" ] && VCOL2=900000 VCOL3=900000
for ENV_NAME in "${ALL_ENVS[@]}"; do
  LEN=$(echo -n ${ENV_NAME} | wc -c)
  ((LEN > COL1)) && COL1=${LEN}
done

# view all env-variables in a table
printf "%-$((COL1+18))s %-$((COL2+18))s %-$((COL3+18))s %-${COL4}s\n" "${HEADER}VARIABLE-NAME${NC}" "${HEADER}CURRENT-VALUE${NC}" "${HEADER}DEFAULT-VALUE${NC}" "${HEADER}STATE${NC}"
for ENV_NAME in ${ALL_ENVS[@]}; do
  STATE=""
  [[ -v "CURRENT_ENVS[${ENV_NAME}]" ]] && IN_USE=1 || IN_USE=0
  if [[ -v "DELETED_ENVS[${ENV_NAME}]" ]]; then
    [ $IN_USE -eq 1 ] && STATE="${RED}deleted${NC}" || STATE="deleted"
    [ "${DELETED_ENVS[${ENV_NAME}]}x" != "x" ] && STATE+=", use ${DELETED_ENVS[${ENV_NAME}]}"
  elif [[ -v "DEPRECATED_ENVS[${ENV_NAME}]" ]]; then
    [ $IN_USE -eq 1 ] && STATE="${YELLOW}deprecated${NC}" || STATE="deprecated"
    [ "${DEPRECATED_ENVS[${ENV_NAME}]}x" != "x" ] && STATE+=", use ${DEPRECATED_ENVS[${ENV_NAME}]}"
  fi
  [ "${#CURRENT_ENVS[${ENV_NAME}]}" -gt "${VCOL2}" ] && CURR_VAL="${CURRENT_ENVS[${ENV_NAME}]:0:$((VCOL2-1))}>" || CURR_VAL="${CURRENT_ENVS[${ENV_NAME}]}"
  [ "${#AVAILABLE_ENVS[${ENV_NAME}]}" -gt "${VCOL3}" ] && AVAI_VAL="${AVAILABLE_ENVS[${ENV_NAME}]:0:$((VCOL3-1))}>" || AVAI_VAL="${AVAILABLE_ENVS[${ENV_NAME}]}"
  printf "%-${COL1}s %-${COL2}s %-${COL3}s %-${COL4}s\n" "${ENV_NAME}" "${CURR_VAL}" "${AVAI_VAL}" "${STATE}"
done