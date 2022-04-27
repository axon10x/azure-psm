#!/bin/bash

resource_group_name=$1

vm_names="$(az vm list -g $resource_group_name -o tsv --query [].name)"

for vm_name in $vm_names
do
	echo "Start ""$vm_name"
	az vm start -g $resource_group_name -n $vm_name --no-wait
done