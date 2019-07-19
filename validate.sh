#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${VALIDATE_SOURCED:-}" = "true" ]] && return 0

## constants ####################################

VALIDATE_SOURCED=true

## properties ###################################

## functions ####################################

function validate {
  # runs validation checks against a set of
  # givn arguments for a specific use type
  type=${1}
  args=${@:2}
  flag="-z"

  [[ "$type" = "file" ]] && flag="! -e"
  for a in $args; do
    if test $flag "${!a:-}"; then
      error "Failed validation" "name=$a" "type=$type"
      exit 3
    fi
  done
}
