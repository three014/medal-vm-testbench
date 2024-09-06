#!/bin/bash

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
export PATH="${SELF%/*}:$PATH"

PROGRAM="${0##*/}"
ARGS=( "$@" )

auto_su() {
  [[ $UID == 0 ]] || exec sudo -p "$PROGRAM must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
}

num=$1

auto_su
virsh --connect qemu:///system undefine --domain medal-test${num}
rm -r /var/lib/libvirt/images/medal/test${num}

