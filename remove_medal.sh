#!/bin/bash

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
export PATH="${SELF%/*}:$PATH"

PROGRAM="${0##*/}"
ARGS=( "$@" )
HOME_DIR="/home/$(logname)"

auto_su() {
  [[ $UID == 0 ]] || exec sudo -p "$PROGRAM must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
}

num=$1

ssh-keygen -f "$HOME_DIR/.ssh/known_hosts" -R "medal-test${num}"

auto_su
virsh --connect qemu:///system shutdown --domain medal-test${num}
sleep 7s
virsh --connect qemu:///system undefine --domain medal-test${num} --remove-all-storage
rm -r /var/lib/libvirt/images/medal/test/test${num} 


