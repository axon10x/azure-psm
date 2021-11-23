#!/bin/bash

templateNsg="../../template/net.nsg.json"
templateVnet="../../template/net.vnet.json"
templateSubnet="../../template/net.vnet.subnet.json"

subscriptionId="$(az account show -o tsv --query 'id')"
location="eastus2"
resourceGroup="core-net"

nsgName="nsg1"
nsgRuleInbound100Src="75.68.47.183"

vnetName="net10"
vnetPrefix="10.0.0.0/16"
subnetName="subnet1"
subnetPrefix="10.0.1.0/24"

# ==================================================

echo "RG"
az group create --subscription "$subscriptionId" -n "$resourceGroup" -l "$location" --verbose

echo "NSG"
az deployment group create --subscription "$subscriptionId" -n "NSG-""$location" --verbose \
	-g "$resourceGroup" --template-file "$templateNsg" \
	--parameters \
	location="$location" \
	nsgName="$nsgName" \
	nsgRuleInbound100Src="$nsgRuleInbound100Src"

echo "VNet"
az deployment group create --subscription "$subscriptionId" -n "VNet-""$location" --verbose \
	-g "$resourceGroup" --template-file "$templateVnet" \
	--parameters \
	location="$location" \
	vnetName="$vnetName" \
	vnetPrefix="$vnetPrefix" \
	enableDdosProtection="false" \
	enableVmProtection="false"

echo "Subnet"
az deployment group create --subscription "$subscriptionId" -n "VNet-Subnet-""$location" --verbose \
	-g "$resourceGroup" --template-file "$templateSubnet" \
	--parameters \
	vnetName="$vnetName" \
	subnetName="$subnetName" \
	subnetPrefix="$subnetPrefix" \
	nsgResourceGroup="$resourceGroup" \
	nsgName="$nsgName" \
	serviceEndpoints="" \
	privateEndpointNetworkPolicies="Enabled" \
	privateLinkServiceNetworkPolicies="Enabled"
