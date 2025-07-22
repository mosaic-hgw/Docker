#!/usr/bin/env bash
# Interaktiv navigator with expand/collapse dirs + view files

#set -euo pipefail

# get commons
source "${HOME}/commons.sh"

VERSION_NUMBER='2025.1.0'
VERSION="\n Version ${VERSION_NUMBER} from 2025-07-21\n Maintained by Ronny Schuldt\n"
MOS_NO_TIME=1
STARTDIR="${ENTRY_USAGE}"
DESTDIR=""
DEFAULT_COLOR="${YELLOW}"
COPY_ALL=false
OPENED=-1
COPIED=-1


usage() {
  echoCol "${DEFAULT_COLOR}
 Usage: $0 [OPTION [...]]

 ${BLUE}-c${DEFAULT_COLOR}       | ${BLUE}--copy-all${DEFAULT_COLOR}           Copy all files directly. -t is needed.
 ${BLUE}-s ${RED}<DIR>${DEFAULT_COLOR} | ${BLUE}--source-dir=${RED}<DIR>${DEFAULT_COLOR}   Directory to explore. Default: ${ENTRY_USAGE}
 ${BLUE}-t ${RED}<DIR>${DEFAULT_COLOR} | ${BLUE}--target-dir=${RED}<DIR>${DEFAULT_COLOR}   Copy selection to this directory.

 ${BLUE}-v${DEFAULT_COLOR}       | ${BLUE}--version${DEFAULT_COLOR}            View current version and maintainer.
 ${BLUE}-n${DEFAULT_COLOR}       | ${BLUE}--version-number${DEFAULT_COLOR}     View only current version-number.
 ${BLUE}-h${DEFAULT_COLOR}       | ${BLUE}--help${DEFAULT_COLOR}               View this information.${NC}
 "
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -s   | --source-dir)
      STARTDIR=$(realpath "${2}")
      [ -d "${STARTDIR}" ] || { echoErr "source dir not found"; exit 1; }
      shift 2 ;;
    -s=* | --source-dir=*)
      STARTDIR=$(realpath "${1#*=}")
      [ -d "${STARTDIR}" ] || { echoErr "source dir not found"; exit 1; }
      shift 1 ;;
    -t   | --target-dir)
      DESTDIR=$(realpath "${2}")
      [ -d "${DESTDIR}" ] || { echoErr "target dir not found"; exit 1; }
      shift 2 ;;
    -t=* | --target-dir=*)
      DESTDIR=$(realpath "${1#*=}")
      [ -d "${DESTDIR}" ] || { echoErr "source dir not found"; exit 1; }
      shift 1 ;;
    -c   | --copy-all)        COPY_ALL=true;                              shift 1 ;;
    -n   | --version-number)  echo "${VERSION_NUMBER}";                   exit 0  ;;
    -v   | --version)         echoCol "${DEFAULT_COLOR}${VERSION}${NC}";  exit 0  ;;
    -h   | --help)            usage;                                      exit 0  ;;
    *)                        echoErr "Unknown option: ${1}";             exit 1  ;;
  esac
done

# copy all files
if ${COPY_ALL}; then
  [ -z "${DESTDIR}" ] && { echoErr "By using --copy-all is --target-dir needed."; exit 1; }
  cp --verbose -rf ${STARTDIR}/* "${DESTDIR}/"
  exit
fi

# arrays for tree‐view
declare -a items
declare -a paths
declare -a levels
declare -a expanded

marker=0

hide_cursor() { tput civis; }
show_cursor() { tput cnorm; }
cls()         { tput clear; tput cup 0 0; OPENED=-1 COPIED=-1; }

build_root() {
  items=(); paths=(); levels=(); expanded=()
  while IFS= read -r entry; do
    full="$STARTDIR/$entry"
    if [ -d "$full" ]; then
      items+=( "$entry/" )
    else
      items+=( "$entry" )
    fi
    paths+=( "$full" )
    levels+=( 0 )
    expanded+=( 0 )
  done < <( ls -A --group-directories-first "$STARTDIR" )
}

expand_node() {
  local idx=$1
  local parent_path=${paths[idx]}
  local parent_level=${levels[idx]}
  local insert=$(( idx + 1 ))

  set +o pipefail
  mapfile -t kids < <( ls -A --group-directories-first "$parent_path" )
  set -o pipefail

  for kid in "${kids[@]}"; do
    full="$parent_path/$kid"
    name="$kid"
    if [ -d "$full" ]; then
      name="$kid/"
    fi
    items=( "${items[@]:0:insert}" "$name" "${items[@]:insert}" )
    paths=( "${paths[@]:0:insert}" "$full" "${paths[@]:insert}" )
    levels=( "${levels[@]:0:insert}" $((parent_level+1)) "${levels[@]:insert}" )
    expanded=( "${expanded[@]:0:insert}" 0 "${expanded[@]:insert}" )
    (( insert++ ))
  done
  expanded[idx]=1
}

collapse_node() {
  local idx=$1
  local lvl=${levels[idx]}
  local end=$(( idx + 1 ))

  while [ $end -lt ${#items[@]} ] && [ "${levels[end]:-0}" -gt "$lvl" ]; do
    (( end++ ))
  done

  items=( "${items[@]:0:idx+1}" "${items[@]:end}" )
  paths=( "${paths[@]:0:idx+1}" "${paths[@]:end}" )
  levels=( "${levels[@]:0:idx+1}" "${levels[@]:end}" )
  expanded=( "${expanded[@]:0:idx+1}" "${expanded[@]:end}" )
  expanded[idx]=0
}

draw() {
  local DEFAULT_COLOR="${YELLOW}"
  echoCol "${BLUE}[↑][↓]${DEFAULT_COLOR} move, ${BLUE}[→]${DEFAULT_COLOR} expand folder/open file, ${BLUE}[←]${DEFAULT_COLOR} collapse folder" false
  [ -n "$DESTDIR" ] && echoCol "${DEFAULT_COLOR}\n${BLUE}[Enter]${DEFAULT_COLOR} Copy selection to ${NC}${DESTDIR}${DEFAULT_COLOR}" false
  echoCol "${DEFAULT_COLOR}, ${BLUE}[Esc]${DEFAULT_COLOR} quit"
  echoCol "${DEFAULT_COLOR}${LINE}\n${STARTDIR}"
  for i in "${!items[@]}"; do
    # 2 spaces per level
    printf "%*s" $(( levels[i]*2 )) ""

    [ $i -eq $marker ] && tput rev

    if [[ "${items[i]}" == */ ]]; then
      if [ "${expanded[i]}" -eq 1 ]; then
        echoCol "${DEFAULT_COLOR}– ${items[i]%/}${NC}" false
      else
        echoCol "${DEFAULT_COLOR}+ ${items[i]%/}${NC}" false
      fi
    else
      echoCol "${DEFAULT_COLOR}  ${items[i]}  ${NC}" false
    fi

    if [ $i -eq $marker ]; then
      tput sgr0
      [ $OPENED -eq $marker ] && echoCol "${DEFAULT_COLOR} -> opened" false
      [ $COPIED -eq $marker ] && echoCol "${DEFAULT_COLOR} -> copied" false
    fi
    echo
  done
}

read_key() {
  IFS= read -rsn1 k
  if [[ $k == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.01 seq || true
    k+="$seq"
  fi
  echo "$k"
}

copy_current() {
  local src=${paths[marker]}
  [ -e "$src" ] || return
  base=$(basename "$src")
  dst="$DESTDIR/$base"
  if [ -e "$dst" ]; then
    #dst="$DESTDIR/${base}_$(date +%s)"
    rm -rf "$dst"
  fi
  if [ -d "$src" ]; then
    cp --verbose -rf "$src" "$dst"
  else
    cp --verbose "$src" "$dst"
  fi
  COPIED=$marker
  echoCol "${DEFAULT_COLOR}\n$LINE${NC}"
}

open_file() {
  cat "${paths[marker]}"
  OPENED=$marker
  echoCol "${DEFAULT_COLOR}\n${LINE}${NC}"
}

cleanup() {
  show_cursor
  #cls
  unset VERSION_NUMBER VERSION MOS_NO_TIME STARTDIR DESTDIR DEFAULT_COLOR COPY_ALL OPENED COPIED marker items paths levels expanded
  exit
}
trap cleanup INT TERM EXIT

hide_cursor && build_root && cls && draw

# mainloop
while true; do
  key=$(read_key)
  case "$key" in

    $'\x1b[A')  # up
      (( marker > 0 )) && { ((marker--)); cls; draw; }
      ;;

    $'\x1b[B')  # down
      (( marker < ${#items[@]}-1 )) && { ((marker++)); cls; draw; }
      ;;

    $'\x1b[C')  # right
      if [[ "${items[marker]}" == */ ]]; then
        [ "${expanded[marker]}" -eq 0 ] && { cls; expand_node $marker; draw; }
      else
        cls; open_file; draw
      fi
      ;;

    $'\x1b[D')  # left
      [[ "${items[marker]}" == */ ]] && [ "${expanded[marker]}" -eq 1 ] && { cls; collapse_node $marker; draw; }
      (( OPENED+COPIED != -2 )) && { cls; draw; }
      ;;

    "")  # Enter to copy selection
      [ -n "$DESTDIR" ] && { cls; copy_current; draw; }
      ;;

    $'\x1b' | 'q' | 'Q')  # Esc|q|Q to exit
      break
      ;;
  esac
done
