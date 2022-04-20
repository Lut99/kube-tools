#!/bin/bash
# RUN BUSYBOX.sh
#  by Lut99
#
# Simple script to run the busybox pod on the Kubernetes cluster for testing.
# Also deletes it afterwards.
#
# There are a few options available to tweak its behaviour; check the README.md.
#


##### CLI #####
# Define default values
node=""
config=""

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
            if [[ "$arg" == "-n" || "$arg" == "--node" ]]; then
                # We'll want to parse its value next
                state="node"
                continue
            
            elif [[ "$arg" == "-c" || "$arg" == "--config" ]]; then
                # We'll want to parse its value next
                state="config"
                continue
            
            elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                # Show the help print
                echo ""
                echo "Usage: $0 [opts]"
                echo ""
                echo "Options:"
                echo "  -n,--node <name>         If given, tries to schedule the busybox on the given node. Nodes are"
                echo "                           assumed to be identifyable by a tag with 'name=<name>'."
                echo "  -c,--config <path>       The path to the config to use when launching busybox. If omitted, uses"
                echo "                           the default kubectl config."
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
            # No positional values for this script
            echo "Unknown positional '$arg' at index $pos_i"
            errored=1
            continue

        fi

    elif [[ "$state" == "node" ]]; then
        # Make sure it's not an option
        if [[ "$accept_opts" -eq 1 && "$arg" =~ ^- ]]; then
            echo "Missing value for '--node'"
            errored=1
            state="start"
            continue
        fi

        # Accept the new name
        node="$arg"

        # Reset back to the normal state
        state="start"

    elif [[ "$state" == "config" ]]; then
        # Make sure it's not an option
        if [[ "$accept_opts" -eq 1 && "$arg" =~ ^- ]]; then
            echo "Missing value for '--config'"
            errored=1
            state="start"
            continue
        fi

        # Accept the new path
        config="$arg"

        # Reset back to the normal state
        state="start"

    else
        echo "ERROR: Illegal state '$state'"
        exit 1
    fi
done

# Catch any flags (states) without values
if [[ "$state" == "node" ]]; then
    echo "Missing value for '--node'"
    errored=1
elif [[ "$state" == "config" ]]; then
    echo "Missing value for '--config'"
    errored=1
fi

# If any errors occurred, stop here
if [[ "$errored" -eq 1 ]]; then
    exit 1
fi





##### RUN BUSYBOX #####
# Construct the command
cmd="kubectl"
if [[ ! -z "$config" ]]; then
    cmd="$cmd --kubeconfig='$config'"
fi
cmd="$cmd -i --tty busybox --image=busybox --restart=Never"
if [[ ! -z "$node" ]]; then
    cmd="$cmd --overrides=\"{\\\"apiVersion}\\\": \\\"v1\\\", \\\"spec\\\": {\\\"nodeSelector\\\": { \\\"name\\\": \\\"$node\\\" }}}\""
fi
cmd="$cmd -- sh"

# Run it
bash -c "$cmd" || exit $?

# Delete the pod afterwards
kubectl delete pod busybox



# Done
