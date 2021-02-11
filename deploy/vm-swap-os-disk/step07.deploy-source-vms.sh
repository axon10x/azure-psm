#!/bin/bash

. ./step00.variables.sh

echo "Deploy Source VMs to use for image capture"

echo "Deploy Source VM1 Public IP"
az deployment group create --subscription "$subscriptionId" -n "VM1-PIP-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$vm1PipNameLocation1" \
	publicIpType="$vmPublicIpType" \
	publicIpSku="$vmPublicIpSku" \
	domainNameLabel="$vm1NameLocation1"

echo "Deploy Source VM2 Public IP"
az deployment group create --subscription "$subscriptionId" -n "VM2-PIP-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templatePublicIp" \
	--parameters \
	location="$location1" \
	publicIpName="$vm2PipNameLocation1" \
	publicIpType="$vmPublicIpType" \
	publicIpSku="$vmPublicIpSku" \
	domainNameLabel="$vm2NameLocation1"

echo "Deploy Source VM1 Network Interface"
az deployment group create --subscription "$subscriptionId" -n "VM1-NIC-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templateNetworkInterface" \
	--parameters \
	location="$location1" \
	networkInterfaceName="$vm1NicNameLocation1" \
	vnetResourceGroup="$rgNameNetLocation1" \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetName" \
	enableAcceleratedNetworking="$enableAcceleratedNetworking" \
	privateIpAllocationMethod="$privateIpAllocationMethod" \
	publicIpResourceGroup="$rgNameSourceLocation1" \
	publicIpName="$vm1PipNameLocation1" \
	ipConfigName="$ipConfigName"

echo "Deploy Source VM2 Network Interface"
az deployment group create --subscription "$subscriptionId" -n "VM2-NIC-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templateNetworkInterface" \
	--parameters \
	location="$location1" \
	networkInterfaceName="$vm2NicNameLocation1" \
	vnetResourceGroup="$rgNameNetLocation1" \
	vnetName="$vnetNameLocation1" \
	subnetName="$subnetName" \
	enableAcceleratedNetworking="$enableAcceleratedNetworking" \
	privateIpAllocationMethod="$privateIpAllocationMethod" \
	publicIpResourceGroup="$rgNameSourceLocation1" \
	publicIpName="$vm2PipNameLocation1" \
	ipConfigName="$ipConfigName"


echo "Retrieve Admin Username and SSH Public Key from Key Vault"
# Note, while we defined these in step00, THAT is to put them INTO Key Vault in step04.
vmAdminUsername="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameAdminUsername" -o tsv --query 'value')"
vmAdminUserSshPublicKey="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameAdminSshPublicKey" -o tsv --query 'value')"

echo "Deploy Source VM1"
az deployment group create --subscription "$subscriptionId" -n "VM1-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location1" \
	virtualMachineName="$vm1NameLocation1" \
	virtualMachineSize="$vmSize" \
	imageResourceId="" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vm1Sku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$vmAdminUsername" \
	adminPublicKey="$vmAdminUserSshPublicKey" \
	virtualMachineTimeZone="$vmTimeZoneLocation1" \
	osDiskStorageType="$osDiskStorageType" \
	osDiskSizeInGB="$osDiskSizeInGB" \
	dataDiskStorageType="$dataDiskStorageType" \
	dataDiskCount="$dataDiskCount" \
	dataDiskSizeInGB="$dataDiskSizeInGB" \
	vmAutoShutdownTime="$vmAutoShutdownTime" \
	enableAutoShutdownNotification="$enableAutoShutdownNotification" \
	autoShutdownNotificationWebhookURL="$autoShutdownNotificationWebhookURL" \
	autoShutdownNotificationMinutesBefore="$autoShutdownNotificationMinutesBefore" \
	resourceGroupNameNetworkInterface="$rgNameSourceLocation1" \
	networkInterfaceName="$vm1NicNameLocation1"

echo "Deploy Source VM2"
az deployment group create --subscription "$subscriptionId" -n "VM2-""$location1" --verbose \
	-g "$rgNameSourceLocation1" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location1" \
	virtualMachineName="$vm2NameLocation1" \
	virtualMachineSize="$vmSize" \
	imageResourceId="" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vm2Sku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$vmAdminUsername" \
	adminPublicKey="$vmAdminUserSshPublicKey" \
	virtualMachineTimeZone="$vmTimeZoneLocation1" \
	osDiskStorageType="$osDiskStorageType" \
	osDiskSizeInGB="$osDiskSizeInGB" \
	dataDiskStorageType="$dataDiskStorageType" \
	dataDiskCount="$dataDiskCount" \
	dataDiskSizeInGB="$dataDiskSizeInGB" \
	vmAutoShutdownTime="$vmAutoShutdownTime" \
	enableAutoShutdownNotification="$enableAutoShutdownNotification" \
	autoShutdownNotificationWebhookURL="$autoShutdownNotificationWebhookURL" \
	autoShutdownNotificationMinutesBefore="$autoShutdownNotificationMinutesBefore" \
	resourceGroupNameNetworkInterface="$rgNameSourceLocation1" \
	networkInterfaceName="$vm2NicNameLocation1"

echo "Source VMs deployed"