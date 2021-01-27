#!/bin/bash

# ==================================================
# Variables
. ./step00.variables.sh
# ==================================================

az group delete --subscription "$subscriptionId" -n "$rgNameDeployLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameSourceLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameSecurityLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameSigLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameNetLocation1" --yes --verbose
