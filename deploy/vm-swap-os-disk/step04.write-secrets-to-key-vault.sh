#!/bin/bash

. ./step00.variables.sh

# Expiration date in 1 year
expirationDate="$(date +%s -d "$(date) + 1 year")"

#echo "Write VM Admin Username to Key Vault"
az deployment group create --subscription "$subscriptionId" -n "KV-""$location1" --verbose \
	-g "$rgNameSecurityLocation1" --template-file "$templateKeyVaultSecret" \
	--parameters \
	location="$location1" \
	keyVaultName="$keyVaultNameLocation1" \
	secretName="$keyVaultSecretNameAdminUsername" \
	secretValue="$adminUsername" \
	expirationDate="$expirationDate"

#echo "Write VM Admin SSH Public Key to Key Vault"
az deployment group create --subscription "$subscriptionId" -n "KV-""$location1" --verbose \
	-g "$rgNameSecurityLocation1" --template-file "$templateKeyVaultSecret" \
	--parameters \
	location="$location1" \
	keyVaultName="$keyVaultNameLocation1" \
	secretName="$keyVaultSecretNameAdminSshPublicKey" \
	secretValue="$adminPublicKey" \
	expirationDate="$expirationDate"
