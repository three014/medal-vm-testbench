#!/bin/bash

set -e -o pipefail
shopt -s extglob
export LC_ALL=C

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
export PATH="${SELF%/*}:$PATH"

PROGRAM="${0##*/}"
ARGS=( "$@" )
HOME_DIR="$HOME"

usage() {
  echo "`basename $0` [NUM] [SSH_KEY_NAME]"
}

# Shamelessly stolen from the wireguard wg-quick script...
auto_su() {
  [[ $UID == 0 ]] || exec sudo -p "$PROGRAM must be run as root. Please enter the password for %u to continue: " -- "$BASH" -- "$SELF" "${ARGS[@]}"
}

die() {
  echo "$PROGRAM: $*" >&2
  exit 1
}

# So was this
if [[ $# -eq 1 && ( $1 == --help || $1 == -h || $1 == help ) ]]; then
  usage
  exit 0
elif [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

num="$1"
key_name="$2"
ssh_pub_key_path="$HOME_DIR/.ssh/keys/$key_name.pub"

mkdir -p /var/lib/libvirt/images/medal

if [ -d "/var/lib/libvirt/images/medal/test${num}" ]; then
  if [ -f "/var/lib/libvirt/images/medal/test${num}/test${num}.qcow2" ]; then
    die "Test number already exists"
  fi
fi

auto_su

cat >/tmp/meta-data <<EOF
local-hostname: medal-test${num}
EOF

cat >/tmp/user-data <<EOF
#cloud-config

package_update: true
package_upgrade: true

packages:
  - git
  - python3-pip

users:
  - name: cc
    ssh-authorized-keys:
      - $(cat ${ssh_pub_key_path})
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

runcmd:
  - echo "AllowUsers cc" >> /etc/ssh/sshd_config
  - restart sshd
EOF

mkdir -p /var/lib/libvirt/images/medal/test${num}
qemu-img create -f qcow2 -F qcow2 -o backing_file=/var/lib/libvirt/images/base/focal-server-cloudimg-amd64.img \
  /var/lib/libvirt/images/medal/test${num}/test${num}.qcow2
qemu-img resize /var/lib/libvirt/images/medal/test${num}/test${num}.qcow2 32G

./gen_cloud_init.sh \
  -o /var/lib/libvirt/images/medal/test${num}/test${num}-cidata.iso \
  -u /tmp/user-data \
  -m /tmp/meta-data

virt-install \
  --connect qemu:///system \
  --virt-type kvm \
  --name medal-test${num} \
  --arch x86_64 \
  --memory 4096 \
  --vcpus=4 \
  --os-variant ubuntu20.04 \
  --disk path=/var/lib/libvirt/images/medal/test${num}/test${num}.qcow2,format=qcow2 \
  --disk /var/lib/libvirt/images/medal/test${num}/test${num}-cidata.iso,device=cdrom \
  --import \
  --network network=medal \
  --noautoconsole

if [ $? -ne 0 ]; then
  code=$?
  ./remove_medal.sh ${num}
  die "Failed to create VM"
fi

cat >> "$HOME_DIR/.ssh/config" <<EOF

Host medal-test${num}
    HostName medal-test${num}.medal.lan
    User cc
    IdentityFile ~/.ssh/keys/${key_name}
EOF

echo "Added new entry to ssh config"

  
