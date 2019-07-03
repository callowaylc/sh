#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${LOG_SOURCED:-}" = "true" ]] && return 0

shopt -s expand_aliases
{ >&3 ;} 2>/dev/null || exec 3>/dev/null
{ >&4 ;} 2>/dev/null || exec 4>/dev/null

## constants ####################################

LOG_SOURCED=true
JOURNALD_SOCK=/run/systemd/journal/socket

## properties ###################################

journald=false

## functions ####################################

function log_open {
  # allocate resources required for logging operations
  local journald=${journald:-}
  local mask=`severity ${PRIORITY:-info}`

  alias mock=":"

  if echo "${SYSLOG:-}" | grep -iE "^true$" &>/dev/null; then
    # if syslog has been explicity requested, check if we are
    # using journald by determing of journald socket is available
    if [[ -S $JOURNALD_SOCK ]]; then
      journald=true
    fi

  else
    # disable syslog function if not explicity required
    alias syslog="read; :"
  fi

  for level in debug info warning error; do
    # iterate though levels and disable those that
    # fall below current mask
    if [[ `severity $level` -gt "$mask" ]]; then
      alias $level=mock
    fi
  done
}
export -f log_open

function log_close {
  # deallocate log resources
  exec 3>&-
  exec 4>&-
}
export -f log_close

function severity {
  local name=${1}
  local value=-1

  {
    if echo $name | grep -i debug ; then
      value=7
    elif echo $name | grep -i info ; then
      value=6
    elif echo $name | grep -i warn ; then
      value=4
    elif echo $name | grep -i err ; then
      value=3
    fi
  } &>/dev/null

  echo $value
}

function debug { logs "debug" "$@" ;}
function info { logs "info" "$@" ;}
function warning { logs "warning" "$@" ;}
function error { logs "error" "$@" ;}
function logs {
  local level=${1}
  local message=${2}
  local sevnum=`severity $level`
  local trace=`caller 1 | sed -E 's/^.+?\s([_a-z0-9]+)\s([-/.a-z0-9]+)$/\2#\1/I'`
  local payload

  if [[ "${3:-}" = "-" ]]; then
    payload=$( cat - )

    IFS=$'\n'
    set -- $level $message `printf '%s ' "$payload"`
    IFS=
  fi

  printf '"%s"\n' \
    "timestamp=`date +%s%N | cut -b1-13`" \
    "level=$level" \
    "priority=$sevnum" \
    "message=$message" \
    "message_id=`uuidgen`" \
    "trace=$trace" \
    "_pid=$$" \
    "${@:3}" \
  | jq -crs '
      map(split("=")
      | {(.[0]): .[1]}
      | with_entries( .key |= ascii_upcase ))
      | add
    ' \
  | >&3 tee >( syslog $level )
}
export -f debug info warning error

function syslog {
  # forward logs to the available system log daemon; if
  # journald is available, it will takes precedence over
  # rsyslog/syslog
  local level=${1}
  local journald=${journald:-}
  local payload

  # read payload from stdin; this will be a json payload and
  # will block if not available
  read payload

  if echo "$journald" | grep -iE "^true$" &>/dev/null; then
    # if journald flag has been set as true, we write to journald
    # udp socket
    printf "$payload" | jq -re '
      to_entries[] | "\( .key )=\( .value )

    ' | nc -Uu -w1 $JOURNALD_SOCK

  else
    # otherwise, write json payload to linux logger, which will
    # take care of details of interacting with syslogd
    printf "$payload" | logger -p $level
  fi
}

## main #########################################

log_open && alias log_open=":"
