#!/bin/bash
set -euo pipefail
! set -o errtrace 2>/dev/null

[[ "${OBFUSCATE_SOURCED:-}" = "true" ]] && return 0

## constants ####################################

OBFUSCATE_SOURCED=true
SALT=A5d

## functions ####################################

function sig {
  # obfuscates a given value by md5 encode
  v="${1:-}${SALT}"

  printf "$v" | md5sum |  cut -d' ' -f1
}
export -f sig

function enc {
  # uses gpg to encrypt a given value
  printf ""
}
