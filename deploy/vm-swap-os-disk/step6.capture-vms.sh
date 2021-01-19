#!/bin/bash

. ./step0.variables.sh

# ##################################################
# IMPORTANT DO NOT SKIP THIS - READ THIS!!!!
# MAKE SURE YOU GENERALIZE THE VMs FIRST!!!!!
# Step 1 at https://docs.microsoft.com/azure/virtual-machines/linux/capture-image
# TODO - could add ssh and sudo waagent -deprovision here, depends if execution context has SSH key needed for that
# OTHERWISE - just SSH into your VMs and do step 1 (doc link) there before actually running this .sh
# ##################################################
# DID YOU READ THE ABOVE? YOU REALLY SHOULD.
# ##################################################

vm1Id="$(az vm show --subscription "$subscriptionId" -g "$rgNameSourceLocation1" -n "$vm1NameLocation1" -o tsv --query "id")"
vm2Id="$(az vm show --subscription "$subscriptionId" -g "$rgNameSourceLocation1" -n "$vm2NameLocation1" -o tsv --query "id")"

# Deallocate the source VMs
# https://docs.microsoft.com/cli/azure/vm?view=azure-cli-latest#az_vm_deallocate
az vm deallocate --subscription "$subscriptionId" -g "$rgNameSourceLocation1" --name "$vm1NameLocation1" --verbose

az vm deallocate --subscription "$subscriptionId" -g "$rgNameSourceLocation1" --name "$vm2NameLocation1" --verbose


# Generalize the source VMs
# https://docs.microsoft.com/cli/azure/vm?view=azure-cli-latest#az_vm_generalize
az vm generalize --subscription "$subscriptionId" -g "$rgNameSourceLocation1" --name "$vm1NameLocation1" --verbose

az vm generalize --subscription "$subscriptionId" -g "$rgNameSourceLocation1" --name "$vm2NameLocation1" --verbose


# Create VM images
# https://docs.microsoft.com/cli/azure/image?view=azure-cli-latest#az_image_create
az image create --subscription "$subscriptionId" -g "$rgNameSigLocation1" --verbose \
	-n "$vm1ImageName" --source "$vm1Id"

az image create --subscription "$subscriptionId" -g "$rgNameSigLocation1" --verbose \
	-n "$vm2ImageName" --source "$vm2Id"


# Get VM Image IDs for SIG Image Version Creation
image1Id="$(az image show --subscription "$subscriptionId" -g "$rgNameSigLocation1" -n "$vm1ImageName" -o tsv --query "id")"
image2Id="$(az image show --subscription "$subscriptionId" -g "$rgNameSigLocation1" -n "$vm2ImageName" -o tsv --query "id")"

# Create Image Version (e.g. from custom image from generalized VM)
# https://docs.microsoft.com/cli/azure/sig/image-version?view=azure-cli-latest#az_sig_image_version_create
az sig image-version create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition1" --gallery-image-version "$imageVersion1" \
	--managed-image "$image1Id" --target-regions "$location1"

az sig image-version create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition2" --gallery-image-version "$imageVersion2" \
	--managed-image "$image2Id" --target-regions "$location1"
