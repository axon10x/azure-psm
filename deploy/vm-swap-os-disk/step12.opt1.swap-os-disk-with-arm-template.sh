#!/bin/bash

. ./step00.variables.sh

echo "Get the resource IDs of the OS disks"
vm3OsDiskIdVersion0="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion0" -o tsv --query "id")"
vm3OsDiskIdVersion1="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion1" -o tsv --query "id")"
vm3OsDiskIdVersion2="$(az disk show --subscription "$subscriptionId" -g "$rgNameDeployLocation1" -n "$vm3OsDiskNameVersion2" -o tsv --query "id")"

echo "Deallocate the existing VM so we can swap in a different OS disk"
az vm deallocate --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --name "$vm3NameLocation1" --verbose

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

az deployment group create --subscription "$subscriptionId" -n "VM3-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templateVirtualMachine" \
	--parameters \
	location="$location1" \
	userAssignedManagedIdentityResourceId="$uamiResourceId" \
	virtualMachineName="$vm3NameLocation1" \
	virtualMachineSize="$vmSize" \
	publisher="$vmPublisher" \
	offer="$vmOffer" \
	sku="$vm3Sku" \
	version="$vmVersion" \
	provisionVmAgent="$provisionVmAgent" \
	adminUsername="$vmAdminUsername" \
	adminPublicKey="$vmAdminUserSshPublicKey" \
	virtualMachineTimeZone="$vmTimeZoneLocation1" \
	osDiskId="$vm3OsDiskIdVersion0" \
	dataDiskStorageType="$dataDiskStorageType" \
	dataDiskCount="$dataDiskCount" \
	dataDiskSizeInGB="$dataDiskSizeInGB" \
	vmAutoShutdownTime="$vmAutoShutdownTime" \
	enableAutoShutdownNotification="$enableAutoShutdownNotification" \
	autoShutdownNotificationWebhookURL="$autoShutdownNotificationWebhookURL" \
	autoShutdownNotificationMinutesBefore="$autoShutdownNotificationMinutesBefore" \
	resourceGroupNameNetworkInterface="$rgNameDeployLocation1" \
	networkInterfaceName="$vm3NicNameLocation1"


echo "Start the VM"
az vm start --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1"
