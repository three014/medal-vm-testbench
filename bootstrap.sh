#!/bin/bash

set -e -o pipefail
shopt -s extglob
export LC_ALL=C

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
export PATH="${SELF%/*}:$PATH"

PROGRAM="${0##*/}"
ARGS=( "$@" )
HOME_DIR="/home/$(logname)"
LIBVIRT_DIR="/var/lib/libvirt"
MEDAL_DIR="${LIBVIRT_DIR}/images/medal"
BASE_IMAGE="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
PROMPT="This script will:
  - Auto-install the entire libvirt suite and qemu-system-x86_64
  - Create the required VM image directories at ${MEDAL_DIR}
  - Create the \"medal0\" network for the VMs
Proceed with the setup process?"

non_interactive=( false )

usage() { 
  echo "Usage: ${PROGRAM} [OPTIONS]
  -y		run non-interactively (assume yes for all prompts)
  -h		display this help and exit"
}

parse_options() {
  TEMP=$(getopt -o hy --long help,yes -- "$@")
  if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

  # Note the quotes around '$TEMP': they are essential!
  eval set -- "$TEMP"

  while true; do
    case "$1" in
      -y | --yes)
        non_interactive=( true )
	shift
	;;
      -h | --help)
	usage
	exit 0
	;;
      --)
        shift
	break
	;;
      *)
        usage
	die "Unknown option."
	;;
    esac
  done
}

auto_su() {
  ARGS=( "$@" -y )
  [[ $UID == 0 ]] || exec sudo -p "$PROGRAM must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
}

die() {
  echo "$PROGRAM: $*" >&2
  exit 1
}

yes_or_no() {
  while true; do
    read -p "$* [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
    esac
  done
}

install_deps() {
  apt update && apt install -y qemu-kvm libvirt-daemon-system genisoimage virtinst systemd-resolved
  usermod -aG libvirt "$(logname)"
  mkdir -p /etc/systemd/system/libvirtd.socket.d
  cat <<EOF >>/etc/systemd/system/libvirtd.socket.d/override.conf
[Socket]
SocketMode=0660
SocketGroup=libvirt
EOF
  systemctl restart libvirtd.socket
}

create_required_directories() {
  mkdir -p "${MEDAL_DIR}/base"
  mkdir -p "${MEDAL_DIR}/test"
  mkdir -p "${HOME_DIR}/.ssh/keys/medal"
  chown -R $(logname):$(logname) "${HOME_DIR}/.ssh"
}

create_medal_network() {
  umask 077
  cat <<EOF > "${LIBVIRT_DIR}/network/medal.xml"
<network>
  <name>medal</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='medal0' stp='on' delay='0'/>
  <domain name='medal.lan'/>
  <ip address='10.94.50.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.94.50.32' end='10.94.50.199'/>
    </dhcp>
  </ip>
</network>
EOF
  virsh --connect qemu:///system net-define "${LIBVIRT_DIR}/network/medal.xml"
  virsh --connect qemu:///system net-autostart medal
  virsh --connect qemu:///system net-start medal
}

download_base_image() {
  cd "${MEDAL_DIR}/base"
  wget "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

parse_options "$@"

if $non_interactive || yes_or_no "$PROMPT"; then
  auto_su
  # echo "Debug: Installer commands has been commented out for safety"
  install_deps
  newgrp libvirt
  create_required_directories
  create_medal_network
  download_base_image
else
  die "Aborted."
fi

echo "Done!"
