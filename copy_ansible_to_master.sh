#!/bin/bash

set -e -o pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
PROGRAM="${0##*/}"

usage() {
  echo "$PROGRAM [HOST]"
}

if [[ $# -eq 1 && ( $1 == --help || $1 == -h || $1 == help ) ]]; then
  usage
  exit 0
elif [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

set -x

scp -r "medal-ansible" "${1}:"
scp "$HOME/.ssh/keys/medal/test" "${1}:.ssh/"
