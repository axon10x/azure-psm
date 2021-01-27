#!/bin/bash

. ./step00.variables.sh

echo "Get the resource IDs of the OS disks"
vm3OsDiskIdVersion0="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion0" -o tsv --query "id")"
vm3OsDiskIdVersion1="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion1" -o tsv --query "id")"
vm3OsDiskIdVersion2="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion2" -o tsv --query "id")"

echo "Deallocate the existing VM so we can swap in the OS disk"
az vm deallocate --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --name "$vm3NameLocation1" --verbose

echo "Update the VM with one of the new OS disk IDs"
# SPECIFY THE CORRECT OS DISK ID TO SWAP -->TO<-- WITH THE --os-disk PARAMETER
az vm update --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1" --os-disk "$vm3OsDiskIdVersion1"

echo "Start the VM"
az vm start --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1"
