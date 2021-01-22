#!/bin/bash

. ./step0.variables.sh

# Get Shared Image Gallery (SIG) Version References
sigImageReference1="$(az sig image-version show --subscription "$subscriptionId" -g "$rgNameSigLocation1" --gallery-name "$sigName" --gallery-image-definition "$imageDefinition1" --gallery-image-version "$imageVersion1" -o tsv --query "id")"
sigImageReference2="$(az sig image-version show --subscription "$subscriptionId" -g "$rgNameSigLocation1" --gallery-name "$sigName" --gallery-image-definition "$imageDefinition2" --gallery-image-version "$imageVersion2" -o tsv --query "id")"

# Create managed OS disks from SIG image versions
# https://docs.microsoft.com/cli/azure/disk?view=azure-cli-latest#az_disk_create

echo "Create Managed OS Disk 1"
az disk create --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -l "$location1" --verbose \
	-n "$vm3OsDiskNameVersion1" --gallery-image-reference "$sigImageReference1" \
	--os-type "$osType" --sku "$osDiskStorageType"

echo "Create Managed OS Disk 2"
az disk create --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -l "$location1" --verbose \
	-n "$vm3OsDiskNameVersion2" --gallery-image-reference "$sigImageReference2" \
	--os-type "$osType" --sku "$osDiskStorageType"
