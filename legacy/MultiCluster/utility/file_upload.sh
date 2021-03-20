#!/bin/bash

resource_group_name=$1
storage_account_name=$2
storage_acct_key=$3
blob_container_name=$4
file_name=$5
file_path=$6

storage_base_url="https://""$storage_account_name"".blob.core.windows.net"

az storage blob upload --account-name "$storage_account_name" --account-key "$storage_acct_key" -c "$blob_container_name" -n "$file_name" -f "$file_path" --verbose

end=`date -u -d "120 minutes" '+%Y-%m-%dT%H:%MZ'`
sas="$(az storage blob generate-sas --account-name "$storage_account_name" --account-key "$storage_acct_key" -c "$blob_container_name" -n "$file_name" --permissions r --expiry $end --https-only)"

file_url="$storage_base_url""/""$blob_container_name""/""$file_name""?""$sas"
file_url=${file_url//\"/""}

echo $file_url
