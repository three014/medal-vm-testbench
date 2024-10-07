# Setting up Docker and Kubernetes using Ansible

Wait, Ansible? Isn't the whole point of this project to use LLM agents to configure a cluster?

Yes! Well, mostly. It's extremely reasonable to assume that the user would want to setup their cluster in a very specific way, so they wouldn't need to use the agent to configure the cluster for them. In this case, it'd be super nice if the agent could assist the user in debugging the Kubernetes configuration, and ideally *fix* the configuration for them, although just being able to point out the causes of the problem would be helpful.

To test our project, we need to simulate all kinds of configuration errors, bugs, network issues, etc. We'll use Ansible to place the virtual cluster into these various states at-will, which will greatly speed up the development process.

Without further ado, let's get started!

## Download the playbook

The cloud config found in [`create_medal.sh`](../create_medal.sh) has entries to install Git, Ansible, and the Pip installer on all new VMs. The ansible playbooks are found in the `medal-ansible` submodule, and can be copied to the any of the VMs with the `copy_ansible_to_master.sh` script. 

## Inside `medal-ansible`

The user can edit the inventory file to include all the desired VMs. New VMs have a FQDN that follows the `medal-testXX.medal.lan` format, where "XX" is the number assigned by the user when they ran `create_medal.sh` with "XX" as the first argument.

A sample inventory file:

```
[worker]
medal-test[02:03]

[master]
medal-test01

[medal:children]
worker
master
```

By default, the "master" kube node will be `medal-test01`, but the user can change this to which node they want.

The playbook can be run from the master VM with this command:

```
ansible-playbook -i inventory.ini bugs/[NAME_OF_PLAYBOOK] --private-key [PATH_TO_SSH_KEY]
```