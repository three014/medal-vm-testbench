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

auto_su
virsh --connect qemu:///system shutdown --domain medal-test${num}
sleep 5s
virsh --connect qemu:///system undefine --domain medal-test${num} --snapshots-metadata --delete-storage-volume-snapshots
rm -r /var/lib/libvirt/images/medal/test${num} 
ssh-keygen -f "$HOME_DIR/.ssh/known_hosts" -R "medal-test${num}.medal.lan"


