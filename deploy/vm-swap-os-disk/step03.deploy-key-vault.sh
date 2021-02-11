#!/bin/bash

. ./step00.variables.sh

echo "Create Key Vault"
az deployment group create --subscription "$subscriptionId" -n "KV-""$location1" --verbose \
	-g "$rgNameSecurityLocation1" --template-file "$templateKeyVault" \
	--parameters \
	location="$location1" \
	tenantId="$tenantId" \
	keyVaultName="$keyVaultNameLocation1" \
	skuName="$keyVaultSkuName"

echo "Assign permissions to current authentication context to get/set/list secrets and keys"
# https://docs.microsoft.com/cli/azure/keyvault?view=azure-cli-latest#az_keyvault_set_policy
az keyvault set-policy --subscription "$subscriptionId" --verbose \
	-g "$rgNameSecurityLocation1" -n "$keyVaultNameLocation1" \
	--object-id "$userObjectId" \
	--key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey \
	--secret-permissions backup delete get list purge recover restore set \
	--certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update

if [ ! -z $userNameUAMILocation1 ]
then
	echo "Assign permissions to UAMI to get/set/list secrets and keys"

	# Get UAMI principal ID first
	uamiPrincipalId="$(az identity show --subscription ""$subscriptionId"" -g ""$rgNameSecurityLocation1"" --name ""$userNameUAMILocation1"" -o tsv --query 'principalId')"
	# Now get the UAMI object ID from the principal ID
	uamiObjectId="$(az ad sp show --id ""$uamiPrincipalId"" -o tsv --query 'objectId')"

	az keyvault set-policy --subscription "$subscriptionId" --verbose \
		-g "$rgNameSecurityLocation1" -n "$keyVaultNameLocation1" \
		--object-id "$uamiObjectId" \
		--key-permissions get \
		--secret-permissions get \
		--certificate-permissions get
fi