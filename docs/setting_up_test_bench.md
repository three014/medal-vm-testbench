# We love virtual machines!

While we do have access to a cluster of raspberry pis to test out our software, the act of resetting the pis to a state where we can repeat experiments takes a bit of time to complete. 

To solve this, I'm working with a virtual cluster using the Libvirt stack to provision new VMs on my host machine. Here's the specs of my machine, as well as the versions of Libvirt and QEMU:
```
host:
	cpu: Intel Core i7-13700KF
	memory: 32gb DDR4
	os: Pop! OS 22.04 LTS
	kernel: 6.9.3-76060903-generic
	gpu: Nvidia GeForce RTX 3070
libvirt:
	version: 10.7.0 (built from source)
qemu:
	version: 9.1.0 (built from source)
```

The specs of the virtual machines are as close as can be to the raspberry pis, with the unfortunate difference that they're x86 VMs. Emulating an arm raspberry pi machine had so many problems on my system, which were outside of my capabilities. For now, the x86 machines work just fine; I've been documenting the differences in configuration for both architectures, but there haven't been too many.

Here's the important parts of the VM configuration:
```
os: Ubuntu 20.04.6 LTS
kernel: 5.4.0-193-generic
vcpus: 4
machine_type: pc-q35-9.1
cpu: host-passthrough, migratable=true
memory: 4gib
on_poweroff: destroy
on_reboot: restart
on_crash: destroy
emulator: /usr/bin/qemu-system-x86_64
disk_vda:
	type: qcow2
	source: /var/lib/libvirt/images/medal/test04/test04.qcow2
	size: 32gib
	backing_store: /var/lib/libvirt/images/base/focal-server-cloudimg-amd64.img
	bus: virtio
cdrom_sda:
	type: raw
	source: /var/lib/libvirt/images/medal/test04/test04-cidata.iso
	bus: sata
	readonly: true
network_vnet1:
	mac: 52:54:00:65:06:e4
	type: virtio
	network: 
		name: medal 
		ipv4_cidr: (10.0.50.0/26)
		forward_mode: nat
	ipv4_addr: 10.0.50.46
```
The full XML configuration can be found [here](../resources/medal-test04.dump.xml).

To initialize each machine, I use a cloud-init config that looks pretty close to this:
```
#cloud-config

package_update: true
package_upgrade: true

packages:
  - git
  - python3-pip

users:
  - name: cc
    ssh-authorized-keys:
      - $(cat "$SSH_PUB_KEY_PATH")
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

runcmd:
  - echo "AllowUsers cc" >> /etc/ssh/sshd_config
  - restart sshd
```

It gets tedious to have to create the right directories, copy the Ubuntu image to the new directories and resize it to 32gib, write out the cloud-config and generate the resulting image, then install the new virtual machine. To alleviate this problem, I created a few helper scripts, which can be found at the base of this repo.

# Using the helper scripts
> [!warning] The format of the options are extremely temporary, and will be changed sometime soon 

(Heavy) Assumptions:
- There is a directory for virtual machine images at `/var/lib/libvirt/images/`, where the base image is located at `/var/lib/libvirt/images/base/focal-server-cloudimg-amd64.img`
- The base image is Ubuntu 20.04.6 LTS x86_64, which can be downloaded from [the Ubuntu cloud images directory](https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img).
- Libvirt and QEMU are installed with the versions mentioned near the beginning of the document
- SSH private and public keys are stored at `~/.ssh/keys/` rather than `~/.ssh/`
	- In the future this won't matter, and the user will be able to name any pub/priv key combo that's compatible with SSH
- The user has a network called "medal" that was created with the virsh tool

Running `./create_medal.sh --help` gives us a simple help line for now:
```
user@hostname:~/medal-vm-testbench$ ./create_medal.sh --help
create_medal.sh [NUM] [SSH_KEY_NAME]
```

To create a new virtual machine named "medal-test05" that accepts your SSH key at `~/.ssh/keys/id_ed25519`, the user can run this in the root folder of the repo:
```
./create_medal.sh 05 id_ed25519
```
where "05" is the suffix that gets added to "medal-test" in both the VM name and hostname, and "id_ed25519" is the name of the private key.

The script will create the required folders and files needed to run the VM, and add a new entry to the user's SSH config file so that the user doesn't have to manually figure out the new VM's IP address. *The script assumes that the public key is stored at the same directory as the private key, and has the same name, plus the ".pub" suffix.*