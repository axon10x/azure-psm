#!/bin/bash

. ./step0.variables.sh

# Create Resource Groups
az group create --subscription "$subscriptionId" -n "$rgNameSigLocation1" -l "$location1" --verbose
az group create --subscription "$subscriptionId" -n "$rgNameNetLocation1" -l "$location1" --verbose
az group create --subscription "$subscriptionId" -n "$rgNameSourceLocation1" -l "$location1" --verbose
az group create --subscription "$subscriptionId" -n "$rgNameDeployLocation1" -l "$location1" --verbose
