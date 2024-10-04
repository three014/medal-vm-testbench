# medal-vm-testbench

This is a repo for setting up and tearing down virtual machines for the purpose of troubleshooting kubernetes configuration problems.

For more info, take a look at the files in doc/

## Getting started

To get started with this repo, run the `bootstrap.sh` script in the
root directory. This will install the libvirt suite, create the test
network for the virtual cluster, and setup the directories for
the VM storage.

At the moment, the script works best if run on a clean system, 
and assumes the user is using Systemd and Debian 12.

## Creating new virtual machines

To spin up a VM, run `create_medal.sh` like so:

```
./create_medal.sh [NUM] [SSH_KEY_NAME]
```

where `NUM` is the suffix placed at the end of the VM name "medal-test",
and `SSH_KEY_NAME` is the name of the private key located in `~/.ssh/keys/medal/`.
