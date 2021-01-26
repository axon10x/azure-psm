#!/bin/bash

. ./step00.variables.sh

# https://docs.microsoft.com/cli/azure/sig/image-definition?view=azure-cli-latest#az_sig_image_definition_create

echo "Create Image Definition 1"
az sig image-definition create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition1" --os-type "$osType" \
	--publisher "$vmPublisher" --offer "$vmOffer" --sku "$vm1Sku" \
	--hyper-v-generation "$hyperVGeneration" --os-state "$osState"

echo "Create Image Definition 2"
az sig image-definition create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName" --gallery-image-definition "$imageDefinition2" --os-type "$osType" \
	--publisher "$vmPublisher" --offer "$vmOffer" --sku "$vm2Sku" \
	--hyper-v-generation "$hyperVGeneration" --os-state "$osState"
