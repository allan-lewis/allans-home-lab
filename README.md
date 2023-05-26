# Home Lab Ansible Scripts

## Regular maintenance

Ensure that localhost is preparted to run playbooks.

~~~
ansible-playbook control.yaml
~~~

Perform basic updates on all nodes.  This will update any dependencies and reboot them, if necessary.  Any k3s nodes will be cordoned during the updates and uncordoned when maintenance is complete.

~~~
ansible-playbook node.yaml --limit "host1,host2"
~~~

Update any Docker containers.

~~~
ansible-playbook docker.yaml
~~~

Update outbound OpenVPN server(s) and update network settings for any node(s) that rely on them.

~~~
ansible-playbook network.yaml
~~~

Schedule any backup tasks.

~~~
ansible-playbook backup.yaml
~~~

Update k3s services.  This will run through most of the k3s playbooks, skipping only the setup of the cluster itself, as well as some of the more critical services whose versions are fixed (Cert Manager, Longhorn).

~~~
ansible-playbook k3s.yaml
~~~

## Kubernetes (k3s)

Create or update a k3s cluster, including installing critial services with fixed versions (Cert Manager, Longhorn).

~~~
ansible-playbook k3s/cluster_setup.yml
~~~

Install or update (nearly) all k3s services.  

~~~
ansible-playbook k3s.yaml
~~~

Destroy a k3s cluster.  This will remove all nodes from the cluster, destroy all associated resources, and reboot all nodes.  Confirmation in the form of a user-defined reset token is required.

~~~
ansible-playbook k3s/cluster_reset.yml
~~~

## DiRT

### Precondition(s)

1. All Longhorn backups are confirmed to be up-to-date
1. Any especially critical data has been manually backed up

### Disaster simulation

Destroy the k3s cluster.

~~~
ansible-playbook k3s/reset.yml
~~~

### Recovery

Re-create the k3 cluster

~~~
ansible-playbook k3s/cluster.yml
~~~

Ensure that Cert Manager certs have been requested successfully.

~~~
kubectl get challenges -A
~~~

~~~
kubectl get certificates -A -o wide
~~~

Manually restore all Longhorn volumes.  Create a volume/PVC for anything not backed up (Prometheus).

Install remaining k3s services.

~~~
ansible-playbook k3s.yaml
~~~

### Success criteria

1. Uptime Kuma shows no errors
1. Grafana shows all hosts operating at reasonable load
1. All volumes are online in Longhorn

## Setup a new node

Setup the basics of the control user using root or another admin user.  

~~~
ansible-playbook nodes.yaml --limit "host1" --ask-pass --ask-become-pass -e "ansible_ssh_user=root"
~~~

Re-run to let the control user finish node setup, including all baseline host setups.  Any nodes designated as Docker nodes will have Docker and its dependencies installed, but no containers will be installed.

~~~
ansible-playbook nodes.yaml --limit "host1"
~~~
