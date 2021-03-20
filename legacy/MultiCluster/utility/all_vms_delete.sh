#!/bin/bash

# This only deletes VMs - not associated NICs, PIPs, disks, etc.

# BE CAREFUL! ARE YOU SURE YOU WANT TO DO THIS?

resource_group_name=$1

vm_names="$(az vm list -g $resource_group_name -o tsv --query [].name)"

for vm_name in $vm_names
do
	echo "Delete ""$vm_name"
	az vm deallocate -g $resource_group_name -n $vm_name --yes --no-wait
done