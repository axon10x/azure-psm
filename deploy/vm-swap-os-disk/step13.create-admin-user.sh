#!/bin/bash

. ./step00.variables.sh

echo "Retrieve SSH Public Key from Key Vault"
# Note, while we defined these in step00, THAT was only to put them INTO Key Vault in step04.
# This retrieval could equally well work if you just run this step / use your own Key Vault info.

# Re-using the SSH key we previously set and used for the initial admin user
# Obviously you can use a different one here
vmAdminUserSshPublicKey="$(az keyvault secret show --subscription "$subscriptionId" --vault-name "$keyVaultNameLocation1" --name "$keyVaultSecretNameAdminSshPublicKey" -o tsv --query 'value')"

echo "Create a new admin user"
# https://docs.microsoft.com/cli/azure/vm/user?view=azure-cli-latest#az_vm_user_update
az vm user update --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1" --username "$newAdminUsername" --ssh-key-value "$vmAdminUserSshPublicKey"
