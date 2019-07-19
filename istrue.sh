#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${ISTRUE_SOURCED:-}" = "true" ]] && return 0

## constants ####################################

ISTRUE_SOURCED=true

## properties ###################################

## functions ####################################

function istrue {
  # Canonical evaluation of boolean true
  value={$1}

  printf '%s' $value | grep -Ei '^true$' &>/dev/null
}
