#!/bin/bash

tenantId="$(az account show -o tsv --query 'tenantId')"
subscriptionId="$(az account show -o tsv --query 'id')"

location="eastus2"
resourceGroupName="pzmaltapp4-rg"
storageAccountName="pzmaltapp4sa"
sku="Standard_LRS"
containerName="loadtest"
sasPolicyName="loadtestaccess"
sasPolicyExpiration="$(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "+ 1 year")"
localFilePath="./default.jmx"
blobName="pzmaltapp4/t1/default.jmx"

# Create storage account
az storage account create --subscription "$subscriptionId" -g "$resourceGroupName" \
  -l "$location" -n "$storageAccountName" --verbose \
  --access-tier Hot \
  --allow-blob-public-access true \
  --allow-cross-tenant-replication false \
  --allow-shared-key-access true \
  --bypass AzureServices Logging Metrics \
  --default-action Allow \
  --https-only true \
  --identity-type None \
  --kind StorageV2 \
  --min-tls-version "TLS1_2" \
  --sku "$sku"

# Get storage account key
acctKey="$(az storage account keys list --subscription "$subscriptionId" -g $resourceGroupName -n "$storageAccountName" -o tsv --query '[0].value')"

# Create container
az storage container create --subscription "$subscriptionId" -g "$resourceGroupName" \
  --account-name "$storageAccountName" --account-key "$acctKey" -n "$containerName" --verbose

# Create container SAS policy
az storage container policy create --subscription "$subscriptionId" \
  --account-name "$storageAccountName" --account-key "$acctKey" \
  -c "$containerName" -n "$sasPolicyName" --expiry "$sasPolicyExpiration" \
  --permissions acdlrw --verbose

# Upload file
az storage blob upload --subscription "$subscriptionId" \
  --account-name "$storageAccountName" --account-key "$acctKey" \
  -f "$localFilePath" -c "$containerName" -n "$blobName" \
  --type block --verbose

# Get SAS URL to access the uploaded blob
blobQs="$(az storage blob generate-sas --subscription "$subscriptionId" --account-name "$storageAccountName" --account-key "$acctKey" -c "$containerName" -n "$blobName" --policy-name "$sasPolicyName" -o tsv --only-show-errors)"
blobUrlRoot="$(az storage blob url --subscription "$subscriptionId" --account-name "$storageAccountName" --account-key "$acctKey" -c "$containerName" -n "$blobName" -o tsv)"

blobUrl="$blobUrlRoot""?""$blobQs"
echo $blobUrl
