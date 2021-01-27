#!/bin/bash

. ./step00.variables.sh

echo "Create a new admin user"
# https://docs.microsoft.com/cli/azure/vm/user?view=azure-cli-latest#az_vm_user_update
az vm user update --subscription "$subscriptionId" -g "$rgNameDeployLocation1" --verbose \
	-n "$vm3NameLocation1" --username "$newAdminUsername" --ssh-key-value "$newAdminSshKeyPath"
