#!/bin/bash

. ./step0.variables.sh

# Get Shared Image Gallery (SIG) Version References
sigImageReference1="$(az sig image-version show --subscription "$subscriptionId" -g "$rgNameSigLocation1" --gallery-name "$sigName" --gallery-image-definition "$imageDefinition1" --gallery-image-version "$imageVersion1" -o tsv --query "id")"
sigImageReference2="$(az sig image-version show --subscription "$subscriptionId" -g "$rgNameSigLocation1" --gallery-name "$sigName" --gallery-image-definition "$imageDefinition2" --gallery-image-version "$imageVersion2" -o tsv --query "id")"
#echo $sigImageReference1
#echo $sigImageReference2

# Create managed OS disks from SIG image versions
# https://docs.microsoft.com/cli/azure/disk?view=azure-cli-latest#az_disk_create
az disk create --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -l "$location1" --verbose \
	-n "$vm3OsDiskNameVersion1" --gallery-image-reference "$sigImageReference1" \
	--os-type "$osType" --sku "$osDiskStorageType"

az disk create --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -l "$location1" --verbose \
	-n "$vm3OsDiskNameVersion2" --gallery-image-reference "$sigImageReference2" \
	--os-type "$osType" --sku "$osDiskStorageType"

# Get the resource IDs of the new OS disks
vm3OsDiskIdVersion1="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion1" -o tsv --query "id")"
vm3OsDiskIdVersion2="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion2" -o tsv --query "id")"
#echo "$vm3OsDiskIdVersion1"
#echo "$vm3OsDiskIdVersion2"

# Deallocate the existing VM so we can swap in the OS disk
az vm deallocate --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --name "$vm3NameLocation1" --verbose

# Update the VM with any of the new OS disk IDs
az vm update --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1" --os-disk "$vm3OsDiskIdVersion2"

# Start the VM
az vm start --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1"
