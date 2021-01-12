#!/bin/bash

. ./step0.variables.sh

# Create NSG
az deployment group create --subscription "$subscriptionId" -n "NSG-""$location1" --verbose \
	-g "$rgNameNetLocation1" --template-file "$templateNsg" \
	--parameters \
	location="$location1" \
	nsgName="$nsgNameLocation1" \
	nsgRuleInbound100Src="$nsgRuleInbound100Src"

# Create VNet
az deployment group create --subscription "$subscriptionId" -n "VNet-""$location1" --verbose \
	-g "$rgNameNetLocation1" --template-file "$templateVnet" \
	--parameters \
	location="$location1" \
	vnetName="$vnetNameLocation1" \
	vnetPrefix="$vnetPrefixLocation1" \
	enableDdosProtection="false" \
	enableVmProtection="false"

# Create Subnet
az deployment group create --subscription "$subscriptionId" -n "VNet-Subnet-""$location1" --verbose \
	-g "$rgNameNetLocation1" --template-file "$templateSubnet" \
	--parameters \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetName" \
	subnetPrefix="$subnetPrefixLocation1" \
	nsgResourceGroup="$rgNameNetLocation1" \
	nsgName="$nsgNameLocation1" \
	serviceEndpoints="" \
	privateEndpointNetworkPolicies="Enabled" \
	privateLinkServiceNetworkPolicies="Enabled"

