#!/bin/bash
# NAME NODES.sh
#   by Lut99
#
# Simple script that tags all nodes with the tag 'name', which is equal to
# their hostname.
#

# Get the nodenames from the kubectl
first=1
kubectl get nodes | while read line; do
    # Skip the first line
    if [[ "$first" -eq 1 ]]; then first=0; continue; fi

    # Only get the first name of each line
    hostname=$(echo $line | awk '{print $1;}')
    
    # Run the command to set the tag
    echo " > kubectl label nodes \"$hostname\" \"name=$hostname\""
    kubectl label nodes "$hostname" "name=$hostname" || exit $?
done

echo ""
echo "Done."
echo ""

