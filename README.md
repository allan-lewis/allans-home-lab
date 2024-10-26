# Allan's Home Lab

## Kubernetes

### Create a cluster



## Regular maintenance

Ensure that control nodes are preparted to run playbooks.

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

Update k3s services.  This will run through most of the k3s playbooks, skipping only the setup of the cluster itself, as well as some of the more critical services whose versions are fixed (Cert Manager, Longhorn).

~~~
ansible-playbook k3s.yaml
~~~

## Kubernetes (k3s)

Create or update a k3s cluster.

~~~
ansible-playbook k3s/cluster_setup.yaml
~~~

Create or update core cluster services.

~~~
ansible-playbook k3s/cluster_core.yaml
~~~

Create or update cluster services.

~~~
ansible-playbook k3s/cluster_services.yaml
~~~

Destroy a k3s cluster.  This will remove all nodes from the cluster, destroy all associated resources, and reboot all nodes.  Confirmation in the form of a user-defined reset token is required.

~~~
ansible-playbook k3s/cluster_reset.yml
~~~

## DiRT

### Precondition(s)

1. All Longhorn backups are confirmed to be up-to-date
1. Any especially critical data has been manually backed up

### Preparation

#### Backup Wiki.js

1. Manually export JSON for Grafana dashboards
1. Export a copy of Uptime Kuma's configuration
1. Export a backup of VaultWarden vaults
1. Take a manual backup of the wiki via the admin console, then copy it locally.

~~
kubectl cp wikijs/wikijs-xxx:/wiki/data ~/Downloads
~~

### Disaster simulation

Destroy the k3s cluster.

~~~
ansible-playbook k3s/cluster_reset.yaml
~~~

### Recovery

Re-create the k3 cluster

~~~
ansible-playbook k3s/cluster_setup.yaml
~~~

Install core cluster services.  This will pause as needed to wait for completion of certificates, volumes, etc.

~~~
ansible-playbook k3s/cluster_core.yaml
~~~

Install everything else to the cluster.

~~~
ansible-playbook k3s/cluster_services.yaml
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
