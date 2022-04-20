#!/bin/bash
# CREATE NAMESPACE USER.sh
#   by Tim Müller
#
# Script to easily setup a new account for that only has access to a certain namespace.
#
# Specifically, sets up a new namespace for the user and then creates a new account that may only access that namespace.
# It then generates a config used to connect to this account.
#


##### CLI #####
# Define default values
namespace=""
cluster="cluster"

# Iterate over the arguments to parse
state="start"
pos_i=0
accept_opts=1
errored=0
for arg in "$@"; do
    # Split on the state
    if [[ "$state" == "start" ]]; then
        # Switch on option or not
        if [[ "$accept_opts" -eq 1 && "$arg" =~ ^- ]]; then
            # Switch on the specific option
            if [[ "$arg" == "-c" || "$arg" == "--cluster" ]]; then
                # We'll want to parse its value next
                state="cluster"
                continue
            
            elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                # Show the help print
                echo ""
                echo "Usage: $0 [opts] <namespace name>"
                echo ""
                echo "Positionals:"
                echo "  <namespace name>         The name of the namespace to create. Other names (such as username,"
                echo "                           role, etc) will be derived from it."
                echo ""
                echo "Options:"
                echo "  -c,--cluster <name>      The name of the cluster to set in the client config file. Default:"
                echo "                           'cluster'"
                echo "  -h,--help                Shows this help string, then quits the script."
                echo "  --                       Interprets all options following this double dash as positionals."
                echo ""

                # Exit, as promised
                exit 0

            elif [[ "$arg" == "--" ]]; then
                # Stop accepting options
                accept_opts=0
                continue

            else
                echo "Unknown option '$arg'"
                errored=1
                continue
            fi

        else
            # It's a positional; switch on the positional index
            if [[ "$pos_i" -eq 0 ]]; then
                # Check if it contains no spaces
                if [[ "$arg" =~ \  ]]; then
                    echo "Namespace name may not contain spaces"
                    errored=1
                    continue
                fi

                # Store the value as the new namespace name
                namespace="$arg"

                # Increment the positional index and continue
                pos_i=1

            else
                echo "Unknown positional '$arg' at index $pos_i"
                errored=1
                continue
            fi

        fi

    elif [[ "$state" == "cluster" ]]; then
        # Make sure it's not an option
        if [[ "$accept_opts" -eq 1 && "$arg" =~ ^- ]]; then
            echo "Missing value for '--cluster'"
            errored=1
            state="start"
            continue
        fi

        # Make sure it does not contain spaces
        if [[ "$arg" =~ \  ]]; then
            echo "Cluster name may not contain spaces"
            errored=1
            state="start"
            continue
        fi

        # Accept the new name
        cluster="$arg"

        # Reset back to the normal state
        state="start"

    else
        echo "ERROR: Illegal state '$state'"
        exit 1
    fi
done

# Catch any flags (states) without values
if [[ "$state" == "cluster" ]]; then
    echo "Missing value for '--cluster'"
    errored=1
fi

# Catch any missing values
if [[ -z "$namespace" ]]; then
    echo "Missing namespace name"
    errored=1
fi

# If any errors occurred, stop here
if [[ "$errored" -eq 1 ]]; then
    exit 1
fi





##### GENERATE NAMESPACE #####
# Simple; run the kubernetes command
echo "Creating new namespace..."
kubectl create namespace "$namespace" || exit $?





##### GENERATE USER ACCOUNT #####
# Next, generate the user account (with role and binding) for this namespace
echo "Generating Role & ServiceAccount..."
cat <<EOT | kubectl create -f - || exit $?
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $namespace-user
  namespace: $namespace

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $namespace-role
  namespace: $namespace

rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["*"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $namespace-view
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $namespace-user
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $namespace-role
EOT





##### CREATE CONFIG #####
# Extract the user token / certificate from the control plane
echo "Extracting user credentials..."
token=$(kubectl -n $namespace describe secret $(kubectl -n $namespace get secret | (grep $namespace-user || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'\n)
cert=$(kubectl  -n $namespace get secret `kubectl -n $namespace get secret | (grep $namespace-user || echo "$_") | awk '{print $1}'` -o "jsonpath={.data['ca\.crt']}")

# Write it to a config file
echo "Generating config to './$namespace-config.yml'..."
cat <<EOT > ./$namespace-config.yml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $cert
    server: https://145.100.134.107:6443
  name: $cluster

contexts:
- context:
    cluster: $cluster
    namespace: $namespace
    user: $namespace-user
  name: $namespace-context

current-context: $namespace-context
kind: Config
preferences: {}

users:
- name: $namespace-user
  user:
    token: $token
    client-key-data: $cert

EOT


echo ""
echo "Done. You can use './$namespace-config.yml' to connect with the shielded account."
echo ""


