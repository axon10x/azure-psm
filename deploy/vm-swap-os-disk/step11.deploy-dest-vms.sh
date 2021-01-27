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

# If a Managed Identity Name was provided, get its Resource ID
if [ ! -z $userNameUAMILocation1 ]
then
	uamiResourceId="$(az identity show --subscription ""$subscriptionId"" -g ""$rgNameSecurityLocation1"" --name ""$userNameUAMILocation1"" -o tsv --query 'id')"
fi

echo "Retrieve Admin Username and SSH Public Key from Key Vault"
# Note, while we defined these in step00, THAT was just to put them INTO Key Vault in step04.
# This retrieval could equally well work if you just run this step / use your own Key Vault info.
vmAdminUsername="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameAdminUsername" -o tsv --query 'value')"
vmAdminUserSshPublicKey="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameAdminSshPublicKey" -o tsv --query 'value')"
#echo $vmAdminUsername
#echo $vmAdminUserSshPublicKey


echo "Deploy VM"
az deployment group create --subscription "$subscriptionId" -n "VM3-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location1" \
	userAssignedManagedIdentityResourceId="$uamiResourceId" \
	virtualMachineName="$vm3NameLocation1" \
	virtualMachineSize="$vmSize" \
	imageResourceId="" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vm3Sku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$vmAdminUsername" \
	adminPublicKey="$vmAdminUserSshPublicKey" \
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
