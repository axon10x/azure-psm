#!/bin/bash

. ./step00.variables.sh

echo "Create Shared Image Gallery"
# https://docs.microsoft.com/cli/azure/sig?view=azure-cli-latest#az_sig_create
az sig create --subscription "$subscriptionId" -g "$rgNameSigLocation1" -l "$location1" --verbose \
	-r "$sigName"
