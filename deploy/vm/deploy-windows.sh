#!/bin/bash

templateUami="../../template/identity.user-assigned-mi.json"
templatePublicIp="../../template/net.public-ip.json"
templateNetworkInterface="../../template/net.network-interface.json"
templateVirtualMachine="../../template/vm.windows.json"

tenantId="$(az account show -o tsv --query 'tenantId')"
subscriptionId="$(az account show -o tsv --query 'id')"
location="eastus2"

infix="core"

resourceGroupName="$infix""-vm"

uamiName="$infix""-uami"

netResourceGroupName="$infix""-net"
vnetName="net10"
subnetName="subnet1"

vmName="$infix""-vm2"

vmPublisher="MicrosoftWindowsDesktop"
vmOffer="Windows-11"
vmSku="win11-21h2-pron"
#vmPublisher="MicrosoftWindowsServer"
#vmOffer="WindowsServer"
#vmSku="2022-datacenter-smalldisk"

vmVersion="latest"

enableAcceleratedNetworking="true" # This is not supported for all VM Sizes - check your VM Size!
provisionVmAgent="true"
vmSize="Standard_D4s_v3"

vmPublicIpType="Dynamic" # Static or Dynamic - Standard SKU requires Static
vmPublicIpSku="Basic" # Basic or Standard
privateIpAllocationMethod="Dynamic"
ipConfigName="ipConfig1"

vmTimeZone="Eastern Standard Time"

osDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
osDiskSizeInGB=127
dataDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
dataDiskCount=0
dataDiskSizeInGB=1023
vmAutoShutdownTime="1800"
enableAutoShutdownNotification="Disabled"
autoShutdownNotificationWebhookURL="" # Provide if set enableAutoShutdownNotification="Enabled"
autoShutdownNotificationMinutesBefore=15

vmAdminUsername="vmadmin"
vmAdminPassword="YOUR_PASSWORD_HERE"

vmPublicIpType="Dynamic" # Static or Dynamic - Standard SKU requires Static
vmPublicIpSku="Basic" # Basic or Standard
vmPipName="$vmName""-pip"

vmNicName="$vmName""-nic"

# ==================================================

echo "RG"
az group create --subscription "$subscriptionId" -n "$resourceGroupName" -l "$location" --verbose

echo "UAMI"
az deployment group create --subscription "$subscriptionId" -n "$uamiName" --verbose \
  -g "$resourceGroupName" --template-file "$templateUami" \
  --parameters \
  location="$location" \
  tenantId="$tenantId" \
  identityName="$uamiName"

echo "VM Public IP"
az deployment group create --subscription "$subscriptionId" -n "$vmPipName" --verbose \
	-g "$resourceGroupName" --template-file "$templatePublicIp" \
	--parameters \
	location="$location" \
	publicIpName="$vmPipName" \
	publicIpType="$vmPublicIpType" \
	publicIpSku="$vmPublicIpSku" \
	domainNameLabel="$vmName"

echo "VM Network Interface"
az deployment group create --subscription "$subscriptionId" -n "$vmNicName" --verbose \
	-g "$resourceGroupName" --template-file "$templateNetworkInterface" \
	--parameters \
	location="$location" \
	networkInterfaceName="$vmNicName" \
	vnetResourceGroup="$netResourceGroupName" \
	vnetName="$vnetName" \
	subnetName="$subnetName" \
	enableAcceleratedNetworking="$enableAcceleratedNetworking" \
	privateIpAllocationMethod="$privateIpAllocationMethod" \
	publicIpResourceGroup="$resourceGroupName" \
	publicIpName="$vmPipName" \
	ipConfigName="$ipConfigName"

uamiId="$(az identity show --subscription ""$subscriptionId"" -g ""$resourceGroupName"" -n ""$uamiName"" -o tsv --query 'id')"

echo "VM"
az deployment group create --subscription "$subscriptionId" -n "$vmName" --verbose \
	-g "$resourceGroupName" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location" \
  userAssignedManagedIdentityResourceId="$uamiId" \
	virtualMachineName="$vmName" \
	virtualMachineSize="$vmSize" \
	imageResourceId="" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vmSku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$vmAdminUsername" \
	adminPassword="$vmAdminPassword" \
	virtualMachineTimeZone="$vmTimeZone" \
	osDiskStorageType="$osDiskStorageType" \
	osDiskSizeInGB="$osDiskSizeInGB" \
	dataDiskStorageType="$dataDiskStorageType" \
	dataDiskCount="$dataDiskCount" \
	dataDiskSizeInGB="$dataDiskSizeInGB" \
	vmAutoShutdownTime="$vmAutoShutdownTime" \
	enableAutoShutdownNotification="$enableAutoShutdownNotification" \
	autoShutdownNotificationWebhookURL="$autoShutdownNotificationWebhookURL" \
	autoShutdownNotificationMinutesBefore="$autoShutdownNotificationMinutesBefore" \
	resourceGroupNameNetworkInterface="$resourceGroupName" \
	networkInterfaceName="$vmNicName"
