#!/bin/bash

. ./step00.variables.sh

echo "Deploy Destination VM to use for OS disk swaps"

echo "Deploy Public IP"
az deployment group create --subscription "$subscriptionId" -n "VM3-PIP-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$vm3PipNameLocation1" \
	publicIpType="$vmPublicIpType" \
	publicIpSku="$vmPublicIpSku" \
	domainNameLabel="$vm3NameLocation1"

echo "Deploy Network Interface"
az deployment group create --subscription "$subscriptionId" -n "VM3-NIC-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templateNetworkInterface" \
	--parameters \
	location="$location1" \
	networkInterfaceName="$vm3NicNameLocation1" \
	vnetResourceGroup="$rgNameNetLocation1" \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetName" \
	enableAcceleratedNetworking="$enableAcceleratedNetworking" \
	privateIpAllocationMethod="$privateIpAllocationMethod" \
	publicIpResourceGroup="$rgNameDeployLocation1" \
	publicIpName="$vm3PipNameLocation1" \
	ipConfigName="$ipConfigName"

echo "Deploy VM"
az deployment group create --subscription "$subscriptionId" -n "VM3-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location1" \
	virtualMachineName="$vm3NameLocation1" \
	virtualMachineSize="$vmSize" \
	imageResourceId="" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vm3Sku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$adminUsername" \
	adminPublicKey="$adminPublicKey" \
	virtualMachineTimeZone="$vmTimeZoneLocation1" \
	osDiskName="$vm3OsDiskNameVersion0" \
	osDiskStorageType="$osDiskStorageType" \
	osDiskSizeInGB="$osDiskSizeInGB" \
	dataDiskStorageType="$dataDiskStorageType" \
	dataDiskCount="$dataDiskCount" \
	dataDiskSizeInGB="$dataDiskSizeInGB" \
	vmAutoShutdownTime="$vmAutoShutdownTime" \
	enableAutoShutdownNotification="$enableAutoShutdownNotification" \
	autoShutdownNotificationWebhookURL="$autoShutdownNotificationWebhookURL" \
	autoShutdownNotificationMinutesBefore="$autoShutdownNotificationMinutesBefore" \
	resourceGroupNameNetworkInterface="$rgNameDeployLocation1" \
	networkInterfaceName="$vm3NicNameLocation1"

echo "Destination VM deployed"