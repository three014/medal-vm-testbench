# Setting up Docker and Kubernetes using Ansible

Wait, Ansible? Isn't the whole point of this project to use LLM agents to configure a cluster?

Yes! Well, mostly. It's extremely reasonable to assume that the user would want to setup their cluster in a very specific way, so they wouldn't need to use the agent to configure the cluster for them. In this case, it'd be super nice if the agent could assist the user in debugging the Kubernetes configuration, and ideally *fix* the configuration for them, although just being able to point out the causes of the problem would be helpful.

To test our project, we need to simulate all kinds of configuration errors, bugs, network issues, etc. We'll use Ansible to place the virtual cluster into these various states at-will, which will greatly speed up the development process.

Without further ado, let's get started!

## Download the playbook

The cloud config found in [`create_medal.sh`](../create_medal.sh) has entries to install Git, Ansible, and the Pip installer on all new VMs, but for now, the user has to manually clone the [Git repository that contains the Ansible playbook](https://github.com/WillClfrd/kube-pi-automation/tree/ansible_stuff) (look for the "ansible_stuff" branch):

```
git clone git@github.com:WillClfrd/kube-pi-automation.git
cd kube-pi-automation
git checkout ansible_stuff
cd ansible
```

Optionally, the user can edit the inventory file to include all the desired VMs. New VMs have a FQDN that follows the `medal-testXX.medal.lan` format, where "XX" is the number assigned by the user when they ran `create_medal.sh` with "XX" as the first argument.

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

Also, the user needs take the private key that was used to connect to the VMs and copy it to the "main" VM. By default this would be `medal-test01.medal.lan`, but it can be any of the VMs as long as the user edits the included `inventory.ini` file to mark the "main" node. This private key will be used by the main VM to SSH into the other VMs and run the Ansible playbook.

Once that's done, `cd` into the folder containing the Ansible playbook and inventory file, and run

```
ansible-playbook -i inventory.ini playbook.yaml --private-key [PATH_TO_SSH_KEY]
```