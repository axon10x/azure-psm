#!/bin/bash

# #####
# Variables

azure_region="eastus"
resource_group_name="azsql"

# Naming prefix - change as you like. Has no functional purpose.
prefix="pzy"

external_ips_allowed="75.68.47.183"

storage_acct_name="$prefix""sqlsa"
storage_container_name="sql"

az_template_sql_srvr="azuresqlserver.template.json"
az_template_sql_db="azuresqldb.template.json"

az_sql_db_sample_bacpac_file="WideWorldImporters-Standard.bacpac"
az_sql_db_sample_bacpac_local_path="./$az_sql_db_sample_bacpac_file"
az_sql_db_sample_download_uri="https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/""$az_sql_db_sample_bacpac_file"
az_sql_db_sample_bacpac_storage_uri="https://""$storage_acct_name"".blob.core.windows.net/""$storage_container_name""/""$az_sql_db_sample_bacpac_file"

az_sql_srvr_name_src="$prefix""-src-""$azure_region"
az_sql_srvr_usr_src="admin-src"
az_sql_srvr_pwd_src="2&tuHT#Li2"

az_sql_db_name_src="srcdb"
az_sql_db_sku_src="P1"
az_sql_db_tier_src="Premium"
az_sql_db_max_size_src=268435456000

az_sql_db_bacpac_file="$az_sql_db_name_src"".bacpac"
az_sql_db_bacpac_local_path="./$az_sql_db_bacpac_file"
az_sql_db_bacpac_storage_uri="https://""$storage_acct_name"".blob.core.windows.net/""$storage_container_name""/""$az_sql_db_bacpac_file"

az_sql_srvr_name_tgt="$prefix""-tgt-""$azure_region"
az_sql_srvr_usr_tgt="admin-tgt"
az_sql_srvr_pwd_tgt="ePk&mXi5xP"

az_sql_db_name_tgt="tgtdb"
az_sql_db_sku_tgt="P1"
az_sql_db_tier_tgt="Premium"
az_sql_db_max_size_tgt=268435456000

# Get email address for alerts - here just use signed-in user's email address
az_alerts_email="$(az ad signed-in-user show -o tsv --query "mail")"

# #####

# #####
# Operations

# https://docs.microsoft.com/en-us/cli/azure/group
echo "Create Resource Group"
az group create -l $azure_region -n $resource_group_name

# https://docs.microsoft.com/en-us/cli/azure/storage/account
echo "Create Storage Account"
az storage account create -l $azure_region -g $resource_group_name -n $storage_acct_name --kind StorageV2 --sku Standard_LRS

# Get storage account key (need it for container create)
# az storage account keys list -n $storage_acct_name -g $resource_group_name
echo "Get Storage Account key"
storage_acct_key="$(az storage account keys list -g "$resource_group_name" -n "$storage_acct_name" -o tsv --query "[0].value")"

# https://docs.microsoft.com/en-us/cli/azure/storage/container
echo "Create Storage Container"
az storage container create -n $storage_container_name --account-name $storage_acct_name --account-key $storage_acct_key

echo "Download the sample database to filesystem, then upload to blob storage. We will use this for the source database."
# Using wget, assuming running in bash
# If need Powershell instead, can use Invoke-WebRequest to download: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-6
wget -O $az_sql_db_sample_bacpac_local_path $az_sql_db_sample_download_uri
az storage blob upload --account-name "$storage_acct_name" --account-key "$storage_acct_key" -c "$storage_container_name" -n "$az_sql_db_sample_bacpac_file" -f "$az_sql_db_sample_bacpac_local_path"
rm $az_sql_db_sample_bacpac_local_path

echo "Create Azure SQL virtual server - source"
az group deployment create -g "$resource_group_name" --name "$az_sql_srvr_name_src" --template-file "$az_template_sql_srvr" --parameters \
    location="$azure_region" server_name="$az_sql_srvr_name_src" server_admin_username="$az_sql_srvr_usr_src" server_admin_password="$az_sql_srvr_pwd_src" \
    alerts_email_address="$az_alerts_email" audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key" \
    firewall_rule_start_ip="$external_ips_allowed" firewall_rule_end_ip="$external_ips_allowed"

echo "Create Azure SQL virtual server - target"
az group deployment create -g "$resource_group_name" --name "$az_sql_srvr_name_tgt" --template-file "$az_template_sql_srvr" --parameters \
    location="$azure_region" server_name="$az_sql_srvr_name_tgt" server_admin_username="$az_sql_srvr_usr_tgt" server_admin_password="$az_sql_srvr_pwd_tgt" \
    alerts_email_address="$az_alerts_email" audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key" \
    firewall_rule_start_ip="$external_ips_allowed" firewall_rule_end_ip="$external_ips_allowed"


echo "Deploy empty source database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$resource_group_name" --name "$az_sql_db_name_src" --template-file "$az_template_sql_db" --parameters \
	location="$azure_region" server_name="$az_sql_srvr_name_src" db_name="$az_sql_db_name_src" \
	db_sku="$az_sql_db_sku_src" db_tier="$az_sql_db_tier_src" db_max_size_bytes="$az_sql_db_max_size_src" \
	db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key"

echo "Deploy empty target database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$resource_group_name" --name "$az_sql_db_name_tgt" --template-file "$az_template_sql_db" --parameters \
    location="$azure_region" server_name="$az_sql_srvr_name_tgt" db_name="$az_sql_db_name_tgt" \
    db_sku="$az_sql_db_sku_tgt" db_tier="$az_sql_db_tier_tgt" db_max_size_bytes="$az_sql_db_max_size_tgt" \
    db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key"



echo "Import sample database into empty source database"
az sql db import -g "$resource_group_name" --server "$az_sql_srvr_name_src" --name "$az_sql_db_name_src" \
    --admin-user "$az_sql_srvr_usr_src" --admin-password "$az_sql_srvr_pwd_src" \
    --storage-uri "$az_sql_db_sample_bacpac_storage_uri" --storage-key "$storage_acct_key" --storage-key-type "StorageAccessKey"

# Work on the source database after importing it from sample... do stuff... get to a point where you're ready to say this source database should now go to the target!

echo "Export source database to bacpac in Azure storage so we can use it for target database(s)"
az sql db export -g "$resource_group_name" --server "$az_sql_srvr_name_src" --name "$az_sql_db_name_src" \
    --admin-user "$az_sql_srvr_usr_src" --admin-password "$az_sql_srvr_pwd_src" \
    --storage-uri "$az_sql_db_bacpac_storage_uri" --storage-key "$storage_acct_key" --storage-key-type "StorageAccessKey"

echo "Import source database into empty target database"
az sql db import -g "$resource_group_name" --server "$az_sql_srvr_name_tgt" --name "$az_sql_db_name_tgt" \
    --admin-user "$az_sql_srvr_usr_tgt" --admin-password "$az_sql_srvr_pwd_tgt" \
    --storage-uri "$az_sql_db_bacpac_storage_uri" --storage-key "$storage_acct_key" --storage-key-type "StorageAccessKey"

# The updated source database should now be in the target server/database

echo "Scale source and target databases down because budget"
az sql db update -g "$resource_group_name" --server "$az_sql_srvr_name_src" --name "$az_sql_db_name_src" --edition Standard --service-objective S0
az sql db update -g "$resource_group_name" --server "$az_sql_srvr_name_tgt" --name "$az_sql_db_name_tgt" --edition Standard --service-objective S0
