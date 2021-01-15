#!/bin/bash

subscriptionId="PROVIDE"
nsgRuleInbound100Src="PROVIDE"

# ARM Templates
templateNsg="../../template/net.nsg.json"
templateVnet="../../template/net.vnet.json"
templateSubnet="../../template/net.vnet.subnet.json"
templatePublicIp="../../template/net.public-ip.json"
templateNetworkInterface="../../template/net.network-interface.json"
templateFirewall="../../template/net.firewall.json"

location1="eastus2"

rgNameLocation1="fw"

nsgNameLocation1="fw-nsg"
vnetNameLocation1="fw-vnet"
vnetPrefixLocation1="10.1.0.0/16"
subnetNameFirewall="AzureFirewallSubnet"
subnetPrefixFirewall="10.1.0.0/24"
subnetNameOther="subnet10"
subnetPrefixOther="10.1.10.0/24"

publicIpType="Static" # Static or Dynamic - Standard SKU requires Static
publicIpSku="Standard" # Basic or Standard
firewallAvailabilityZones="1,2,3"

pipNameZrLocation1="pip-fw-zr"
pipNameZ1Location1="pip-fw-z1"
pipNameZ2Location1="pip-fw-z2"
pipNameZ3Location1="pip-fw-z3"

firewallSku="AZFW_VNet"
firewallTier="Standard"
firewallThreatIntelMode="Alert"

firewallNameLocation1="fw-""$location1"

# RG
az group create --subscription "$subscriptionId" -n "$rgNameLocation1" -l "$location1" --verbose

# NSG
az deployment group create --subscription "$subscriptionId" -n "NSG-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templateNsg" \
	--parameters \
	location="$location1" \
	nsgName="$nsgNameLocation1" \
	nsgRuleInbound100Src="$nsgRuleInbound100Src"

# VNet / Subnets
az deployment group create --subscription "$subscriptionId" -n "VNet-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templateVnet" \
	--parameters \
	location="$location1" \
	vnetName="$vnetNameLocation1" \
	vnetPrefix="$vnetPrefixLocation1" \
	enableDdosProtection="false" \
	enableVmProtection="false"

az deployment group create --subscription "$subscriptionId" -n "VNet-Subnet-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templateSubnet" \
	--parameters \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetNameFirewall" \
	subnetPrefix="$subnetPrefixFirewall"

az deployment group create --subscription "$subscriptionId" -n "VNet-Subnet-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templateSubnet" \
	--parameters \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetNameOther" \
	subnetPrefix="$subnetPrefixOther" \
	nsgResourceGroup="$rgNameLocation1" \
	nsgName="$nsgNameLocation1"

# PIPs - ZR, Z1, Z2, Z3
az deployment group create --subscription "$subscriptionId" -n "PIP-ZR-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$pipNameZrLocation1" \
	publicIpType="$publicIpType" \
	publicIpSku="$publicIpSku" \
	domainNameLabel="$pipNameZrLocation1"

az deployment group create --subscription "$subscriptionId" -n "PIP-Z1-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$pipNameZ1Location1" \
	publicIpType="$publicIpType" \
	publicIpSku="$publicIpSku" \
	domainNameLabel="$pipNameZ1Location1" \
	availabilityZone="1"

az deployment group create --subscription "$subscriptionId" -n "PIP-Z2-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$pipNameZ2Location1" \
	publicIpType="$publicIpType" \
	publicIpSku="$publicIpSku" \
	domainNameLabel="$pipNameZ2Location1" \
	availabilityZone="2"

az deployment group create --subscription "$subscriptionId" -n "PIP-Z3-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$pipNameZ3Location1" \
	publicIpType="$publicIpType" \
	publicIpSku="$publicIpSku" \
	domainNameLabel="$pipNameZ3Location1" \
	availabilityZone="3"

# FW
az deployment group create --subscription "$subscriptionId" -n "FW-""$location1" --verbose \
	-g "$rgNameLocation1" --template-file "$templateFirewall" \
	--parameters \
	location="$location1" \
	vnetResourceGroup="$rgNameLocation1" \
	vnetName="$vnetNameLocation1" \
	firewallName="$firewallNameLocation1" \
	firewallAvailabilityZones="$firewallAvailabilityZones" \
	firewallSku="$firewallSku" \
	firewallTier="$firewallTier" \
	firewallThreatIntelMode="$firewallThreatIntelMode" \
	publicIpResourceGroup="$rgNameLocation1" \
	publicIpAddressNames="$pipNameZrLocation1, $pipNameZ1Location1"
