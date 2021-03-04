#!/bin/bash

. ./step00.variables.sh

# Expiration date in 1 year from "today" - adust as needed
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
	secretValue="$adminSshPublicKey" \
	expirationDate="$expirationDate"

#echo "Write New VM Admin Username to Key Vault"
az deployment group create --subscription "$subscriptionId" -n "KV-""$location1" --verbose \
	-g "$rgNameSecurityLocation1" --template-file "$templateKeyVaultSecret" \
	--parameters \
	location="$location1" \
	keyVaultName="$keyVaultNameLocation1" \
	secretName="$keyVaultSecretNameNewAdminUsername" \
	secretValue="$newAdminUsername" \
	expirationDate="$expirationDate"

#echo "Write New VM Admin SSH Public Key to Key Vault"
az deployment group create --subscription "$subscriptionId" -n "KV-""$location1" --verbose \
	-g "$rgNameSecurityLocation1" --template-file "$templateKeyVaultSecret" \
	--parameters \
	location="$location1" \
	keyVaultName="$keyVaultNameLocation1" \
	secretName="$keyVaultSecretNameNewAdminSshPublicKey" \
	secretValue="$newAdminSshPublicKey" \
	expirationDate="$expirationDate"
