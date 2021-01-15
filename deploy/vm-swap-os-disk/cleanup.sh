#!/bin/bash

# ==================================================
# Variables
. ./step0.variables.sh
# ==================================================

az group delete --subscription "$subscriptionId" -n "$rgNameDeployLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameSourceLocation1" --yes --verbose

az group delete --subscription "$subscriptionId" -n "$rgNameSigLocation1" --yes --verbose
az group delete --subscription "$subscriptionId" -n "$rgNameNetLocation1" --yes --verbose
