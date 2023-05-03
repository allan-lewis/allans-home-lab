# Home Lab Ansible Scripts

## Setup a new node

Setup the basics of the control (ansible) user using root or another admin user.  

`ansible-playbook nodes.yaml --limit "hostname" --ask-password --ask-become-password -e "ansible_ssh_user=root"`

Re-run to let the control user finish node setup, including all baseline host setups.  Any nodes designated as Docker nodes will have Docker and its dependencies installed, but no containers will be installed.

`ansible-playbook nodes.yaml --limit "hostname"`

