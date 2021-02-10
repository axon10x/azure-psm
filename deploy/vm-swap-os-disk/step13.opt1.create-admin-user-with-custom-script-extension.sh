#!/bin/bash

. ./step00.variables.sh

echo "Retrieve new Admin Username and SSH Public Key from Key Vault"
# Note, while we defined these in step00, THAT was only to put them INTO Key Vault in step04.
# This retrieval could equally well work if you just run this step / use your own Key Vault info.
vmNewAdminUsername="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameNewAdminUsername" -o tsv --query 'value')"
vmNewAdminUserSshPublicKey="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameNewAdminSshPublicKey" -o tsv --query 'value')"

# If a Managed Identity Name was provided, get its Principal ID for the custom script extension deploy below
# This is useful if the custom script task is modified to retrieve a file from an Azure Storage account where the managed identity has access permissions
if [ ! -z $userNameUAMILocation1 ]
then
	uamiPrincipalId="$(az identity show --subscription ""$subscriptionId"" -g ""$rgNameSecurityLocation1"" --name ""$userNameUAMILocation1"" -o tsv --query 'principalId')"
fi

# RHEL
# TODO - Ubuntu version - will need to change the usermod line to make new user an admin
script="
sudo useradd ""$vmNewAdminUsername"";
sudo usermod -aG wheel ""$vmNewAdminUsername"";
sudo mkdir -p /home/""$vmNewAdminUsername""/.ssh;
sudo echo \"""$vmNewAdminUserSshPublicKey""\"  > ""$vmNewAdminUsername"".txt;
sudo cp ./""$vmNewAdminUsername"".txt /home/""$vmNewAdminUsername""/.ssh/authorized_keys
sudo chmod 700 /home/""$vmNewAdminUsername""/.ssh;
sudo chmod 600 /home/""$vmNewAdminUsername""/.ssh/authorized_keys;
sudo chown -R ""$vmNewAdminUsername"":""$vmNewAdminUsername"" /home/""$vmNewAdminUsername""/.ssh;
sudo echo \"""$vmNewAdminUsername""	ALL=(ALL)	NOPASSWD: ALL\" > /etc/sudoers.d/020_""$vmNewAdminUsername"";
"

echo "Create a new admin user"
az deployment group create --subscription "$subscriptionId" -n "VM-Ext-CustomScript-""$location1" --verbose \
	-g "$rgNameDeployLocation1" --template-file "$templateVirtualMachineExtensionCustomScript" \
	--parameters \
	location="$location1" \
	virtualMachineName="$vm3NameLocation1" \
	script="$script" \
	managedIdentity="$uamiPrincipalId"
