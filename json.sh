#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${JSON_SOURCED:-}" = "true" ]] && return 0

## constants ####################################

JSON_SOURCED=true

## properties ###################################

## functions ####################################

function keys {
  # writes comma delimited list to stdout
  local p=${1:-}
  local sep=${2:-,}

  [[ "$p" = "-" ]] && p=`cat` ||:
  printf "$p" | jq -er 'keys | map(.[:2]) | join(",")'
}
