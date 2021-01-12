#!/bin/bash

. ./step0.variables.sh

# Create Shared Image Gallery
# https://docs.microsoft.com/cli/azure/sig?view=azure-cli-latest#az_sig_create
az sig create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName"

# Create Image Definition
# https://docs.microsoft.com/cli/azure/sig/image-definition?view=azure-cli-latest#az_sig_image_definition_create
az sig image-definition create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition1" --os-type "$osType" \
	--publisher "$vmPublisher" --offer "$vmOffer" --sku "$vm1Sku" \
	--hyper-v-generation "$hyperVGeneration" --os-state "$osState"

az sig image-definition create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition2" --os-type "$osType" \
	--publisher "$vmPublisher" --offer "$vmOffer" --sku "$vm2Sku" \
	--hyper-v-generation "$hyperVGeneration" --os-state "$osState"
