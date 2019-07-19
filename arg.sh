#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${ARG_SOURCED:-}" = "true" ]] && return 0

## constants ####################################

ARG_SOURCED=true

## properties ###################################

## functions ####################################

function arg {
  # Enforces rules around assignment when working
  # with positional arguments
  # `arg unsigned`

  printf "${@:-\0}" \
    | sed -E '/^-/!q1;s/-//' && cat \
    ||:
}
