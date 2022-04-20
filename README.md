# Kubernetes Tools
A small repository containing a collection of convencience scripts for managing a Kubernetes cluster.

It also contains a very simple 'hello-world' service that may be used for testing.


## Overview
The following scripts are available:
- `./run-busybox.sh`: Runs a busybox and connects the current shell to it. May be used for inspect in-cluster network or doing in-cluster operations. After 'exit', the pod will automatically be removed.
- `./name-nodes.sh`: For each node in the cluster, gives it a separate tag with its hostname.
- `./create-namespace-user.sh`: Creates a new namespace and a user account that only has access to that namespace. Then, a config is generated, which may be handed to other people who will only be able to do stuff in that namespace.

See below for a more detailed description per script.

The simple service is called the `service-test` service, and can be found under `./service-test`.


## Scripts
A more detailled description of each of the services may be found here.

### run-busybox.sh
This script runs the standard Busybox pod and connects the current shell to it. It may be used to test in-cluster network, or perform other operations that require access from within the cluster.

It supports a couple of flags:
- `-n,--node <name>`: Name of the node to try to force the busybox pod on. Note that it assumes that there is a 'name' tag on each node that will identify it (check the [name-nodes.sh](#name-nodes.sh) script).
- `-N,--namespace <name>`: Name of the namespace where the busybox cluster should live. Will user `kubectl`'s default if omitted.
- `-c,--config <path>`: Use a different config to launch the pod. This may be useful in case the pod should be created for a user with a different access level.


### name-nodes.sh
For each node in the cluster, gives it a separate tag with its hostname.

The tag name is `name`, and its value is copied from the `kubectl get nodes` command.

Currently, this script supports no flags to change this behaviour.


### create-namespace-user.sh
This script creates a new namespace and then a user account who's access is limited to the newly created namespace. Then, to finish off, it generates a config so this cluster may be accessed using that shielded account.

The name of the namespace is given as the first (and only) positional argument. Additionally, it also supports the following flags:
- `-c,--cluster <name>`: The name of the cluster as known on the client-side. Will default to `cluster` if omitted.

Assuming that `<namespace>` is the given name of the namespace, the script generates the following additional resources:
- `<namespace>-user`: The ServiceAccount that only has access to this namespace.
- `<namespace>-role`: The Role that only has access to this namespace.
- `<namespace>-view`: The RoleBinding that binds the `<namespace>-role` to the `<namespace>-user`.

The config file also generates the following resources on the client side (assuming that `<namespace>` is still the namespace name, and `<cluster>` is the cluster name):
- `<cluster>`: The Cluster to which the client shall connect.
- `<namespace>-context`: The Context for this user-account, which connects the current cluster with the `<namespace>-user` account.

Note that the namespace name may contain any spaces at this time.


## Contact
If you have any suggestions, updates or encounter any bugs, feel free to create issues in the repository's [issues](https://github.com/Lut99/kube-tools/issues) section. 

You may also create pull requests if you wrote an update or a fix yourself. I'll look at it as soon as I can.
