#!/bin/bash

# Login first
# az login

echo "This script assumes you are at a terminal in the azure folder, i.e. co-located with this script"
echo "You should have replaced ###PROVIDE### tokens with meaningful values for your environment before running this!"

# ##################################################
# Variables
# Internal / for script
azure_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# General
prefix="apz"   # This is just a naming prefix used to create other variable values, like resource group names and such

azure_aad_tenant_id="$(az account show -o tsv --query "tenantId")"
azure_subscription_id="$(az account show -o tsv --query "id")"
azure_region="eastus"
azure_external_ips_allowed="75.68.47.183"
azure_alerts_email_address="$(az ad signed-in-user show -o tsv --query "mail")"   # Obviously if you have an organizational standard use that - this uses the email of the signed-in user

# Resource group
azure_resource_group_name="$prefix-a"

# Service principal - note that SP names must begin with "http://"
azure_sp_display_name="$prefix""-poc-sp"
azure_sp_name="http://""$azure_sp_display_name"
azure_sp_scope="/subscriptions/""$azure_subscription_id""/resourceGroups/""$azure_resource_group_name"

# Storage account and containers
azure_storage_acct_name="$prefix""pocsa"
azure_storage_acct_sku=Standard_LRS
azure_container_name_staging_ref="staging-ref"
azure_container_name_staging_tx="staging-tx"
azure_container_name_bacpac="bacpac"

# Storage scopes and role for service principal authentication/authorization
# Container level would be: /subscriptions/<subscription>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account>/blobServices/default/containers/<container-name>
# For ADF connection setup, need account-level though (confirm)
azure_storage_scope_staging="/subscriptions/""$azure_subscription_id""/resourceGroups/""$azure_resource_group_name""/providers/Microsoft.Storage/storageAccounts/""$azure_storage_acct_name"
azure_storage_sp_role="Storage Blob Data Contributor"

# Azure SQL virtual server
azure_sql_server_admin_sql_username="$prefix""-sqladmin"
azure_sql_server_admin_sql_password="W00hoo@@2019"

azure_sql_server_admin_aad_display_name="$(az ad signed-in-user show -o tsv --query "displayName")"   # Or provide a display name for another principal
azure_sql_server_admin_aad_principal_id="$(az ad signed-in-user show -o tsv --query "objectId")"   # Or provide another principal's (the same as for display name!) principal ID

azure_template_path_sql_server="$azure_dir""/azuresqlserver.template.json"
azure_sql_server_name="$prefix""-sql-""$azure_region"

azure_template_path_sql_database="$azure_dir""/azuresqldb.template.json"

# Azure SQL security
azure_sql_security_adf_role_name="ADFRole"  # This must match what's in the SQL files and bacpacs! Do not change this until/unless you know exactly what you're doing and have changed it in those other places!!!

# Azure SQL databases
azure_sql_db_ref_name="$prefix""-ref-db"
azure_sql_db_ref_sku="S1"
azure_sql_db_ref_tier="Standard"
azure_sql_db_ref_max_size_bytes=268435456000
azure_sql_db_ref_bacpac_file="ref-db.bacpac"
azure_sql_db_ref_bacpac_path="$azure_dir""/sql/""$azure_sql_db_ref_bacpac_file"
azure_sql_db_ref_bacpac_storage_uri="https://""$azure_storage_acct_name"".blob.core.windows.net/""$azure_container_name_bacpac""/""$azure_sql_db_ref_bacpac_file"

azure_sql_db_tx_staging_name="$prefix""-tx-staging-db"
azure_sql_db_tx_staging_sku="S1"
azure_sql_db_tx_staging_tier="Standard"
azure_sql_db_tx_staging_max_size_bytes=268435456000
azure_sql_db_tx_staging_bacpac_file="tx-staging-db.bacpac"
azure_sql_db_tx_staging_bacpac_path="$azure_dir""/sql/""$azure_sql_db_tx_staging_bacpac_file"
azure_sql_db_tx_staging_bacpac_storage_uri="https://""$azure_storage_acct_name"".blob.core.windows.net/""$azure_container_name_bacpac""/""$azure_sql_db_tx_staging_bacpac_file"

azure_sql_db_tx_prod_name="$prefix""-tx-prod-db"
azure_sql_db_tx_prod_sku="S1"
azure_sql_db_tx_prod_tier="Standard"
azure_sql_db_tx_prod_max_size_bytes=268435456000
azure_sql_db_tx_prod_bacpac_file="tx-prod-db.bacpac"
azure_sql_db_tx_prod_bacpac_path="$azure_dir""/sql/""$azure_sql_db_tx_prod_bacpac_file"
azure_sql_db_tx_prod_bacpac_storage_uri="https://""$azure_storage_acct_name"".blob.core.windows.net/""$azure_container_name_bacpac""/""$azure_sql_db_tx_prod_bacpac_file"

# On-premise SQL
# These come from the on-premise deployment - retrieve from Azure portal if using the stand-in on-prem environment deployed to Azure,
#    or from your environment if using with a deployed self-hosted integration runtime (SHIR). Use hostnames or IP addresses visible to the SHIR (which means internal IPs are fine).
on_prem_sql_server_ref_name="10.1.1.4"
on_prem_sql_server_tx_name="10.1.1.5"
# These are defined in the onprem/deploy.sh and onprem/sql/*-db.sql files so do not change these arbitrarily without also changing them there and deploying appropriately!
on_prem_sql_db_ref_name="RefDb"
on_prem_sql_db_tx_name="TxDb"
on_prem_sql_username="SqlAdfUser1"
on_prem_sql_password="P@ssw0rd2019!"  # Do not change this unless you also change it in the onprem SQL scripts. Yes, I know. It's a password in the clear. It's for an on-prem environment and it's useless other than here. In production it would make sense to echo out the SQL and other scripts using a value from an Azure Key Vault, for example.

# Azure Data Factory
azure_template_path_adf_step1="$azure_dir""/adf-step1.template.json"
azure_template_path_adf_step2="$azure_dir""/adf-step2.template.json"
azure_adf_factory_name="$prefix""-adf"
azure_adf_ir_name="$prefix""-ir"
azure_adf_script_step1="$azure_dir""/deploy-adf-step1.sh"
azure_adf_script_step2="$azure_dir""/deploy-adf-step2.sh"

# API connection from Logic App to Data Factory
azure_template_path_api_connection="$azure_dir""/apiconnection.template.json"
azure_api_connection_name="$azure_adf_factory_name""-conn"

# Azure Logic App
azure_template_path_logic_app="$azure_dir""/logicapp.template.json"
azure_logic_app_name="$prefix""-la"
azure_adf_pipeline_name="tx_staging_to_prod_incremental"

azure_api_connection_and_logic_app_script="$azure_dir""/deploy-logic-app.sh"
# ##################################################

# ##################################################
echo "Create resource group"
az group create -l "$azure_region" -n "$azure_resource_group_name" --verbose

echo -e "\n"
echo "Create service principal in Contributor role for Azure RG"
# Password is only revealed at SP creation. It is included in the output from az ad sp create.
azure_sp_password="$(az ad sp create-for-rbac -n "$azure_sp_name" --role "contributor" --years 2 --scopes "$azure_sp_scope" -o tsv --query "password")"

# Get the application/client ID for the newly created SP
azure_sp_app_client_id="$(az ad sp show --id "$azure_sp_name" -o tsv --query "appId")"

# Update the SP display name to the one we prepared (otherwise it's something set by AAD - that would work too but this gives us more control over the list of App registrations)
az ad app update --id "$azure_sp_app_client_id" --set displayName="$azure_sp_display_name"

# Verify that the SP display name update was successful by overwriting the one we prepared with the updated one from AAD
azure_sp_display_name="$(az ad sp show --id "$azure_sp_app_client_id" -o tsv --query "displayName")"

echo "Service Principal Name: ""$azure_sp_name"
echo "Service Principal Display Name: ""$azure_sp_display_name"
echo "Service Principal Application/Client ID: ""$azure_sp_app_client_id"
echo "Service Principal Key/Password: ""$azure_sp_password"
echo "Service Principal Authorization Scope: ""$azure_sp_scope"

echo -e "\n"

echo "Create storage account"
az storage account create -l "$azure_region" -g "$azure_resource_group_name" -n "$azure_storage_acct_name" --sku "$azure_storage_acct_sku" --kind StorageV2 --assign-identity --verbose

# Here for reference - don't need it for this deployment though as we're working with service principals, not managed service identities
# azure_storage_account_identity_tenant_id="$(az storage account show -g "$azure_resource_group_name" -n "$azure_storage_acct_name" -o tsv --query "identity.tenantId")"
# azure_storage_account_identity_principal_id="$(az storage account show -g "$azure_resource_group_name" -n "$azure_storage_acct_name" -o tsv --query "identity.principalId")"
# echo $azure_storage_account_identity_tenant_id
# echo $azure_storage_account_identity_principal_id

echo -e "\n"
echo "Get storage account key"
azure_storage_acct_key="$(az storage account keys list -g "$azure_resource_group_name" -n "$azure_storage_acct_name" -o tsv --query "[0].value")"

echo -e "\n"
echo "Create storage containers"
az storage container create --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -n "$azure_container_name_staging_tx" --verbose
az storage container create --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -n "$azure_container_name_staging_ref" --verbose
az storage container create --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -n "$azure_container_name_bacpac" --verbose

echo -e "\n"
echo "Assign service principal rights to read/write data to staging data storage account for ADF orchestration (this is redundant with RG Contributor, but OK to do and needed if the storage acct is in another RG)"
az role assignment create --scope "$azure_storage_scope_staging" --assignee "$azure_sp_name" --role "$azure_storage_sp_role" --verbose

echo -e "\n"
echo "Upload bacpac files to import into Azure SQL databases"
az storage blob upload --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -c "$azure_container_name_bacpac" -n "$azure_sql_db_ref_bacpac_file" -f "$azure_sql_db_ref_bacpac_path" --verbose
az storage blob upload --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -c "$azure_container_name_bacpac" -n "$azure_sql_db_tx_staging_bacpac_file" -f "$azure_sql_db_tx_staging_bacpac_path" --verbose
az storage blob upload --account-name "$azure_storage_acct_name" --account-key "$azure_storage_acct_key" -c "$azure_container_name_bacpac" -n "$azure_sql_db_tx_prod_bacpac_file" -f "$azure_sql_db_tx_prod_bacpac_path" --verbose

echo -e "\n"
echo "Create Azure SQL virtual server"
az group deployment create -g "$azure_resource_group_name" -n "$azure_sql_server_name" --template-file "$azure_template_path_sql_server" --verbose --parameters \
location="$azure_region" server_name="$azure_sql_server_name" server_admin_username="$azure_sql_server_admin_sql_username" server_admin_password="$azure_sql_server_admin_sql_password" \
alerts_email_address="$azure_alerts_email_address" audit_storage_account_name="$azure_storage_acct_name" audit_storage_account_key="$azure_storage_acct_key" \
firewall_rule_start_ip="$azure_external_ips_allowed" firewall_rule_end_ip="$azure_external_ips_allowed"

echo -e "\n"
echo "Configure Azure SQL virtual server AD Admin"
az sql server ad-admin create -g "$azure_resource_group_name" -s "$azure_sql_server_name" -u "$azure_sql_server_admin_aad_display_name" -i "$azure_sql_server_admin_aad_principal_id" --verbose

echo -e "\n"
echo "Deploy Ref database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$azure_resource_group_name" -n "$azure_sql_db_ref_name" --template-file "$azure_template_path_sql_database" --verbose --parameters \
location="$azure_region" server_name="$azure_sql_server_name" db_name="$azure_sql_db_ref_name" \
db_sku="$azure_sql_db_ref_sku" db_tier="$azure_sql_db_ref_tier" db_max_size_bytes="$azure_sql_db_ref_max_size_bytes" \
db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$azure_storage_acct_name" audit_storage_account_key="$azure_storage_acct_key"

echo -e "\n"
echo "Deploy Tx Staging database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$azure_resource_group_name" -n "$azure_sql_db_tx_staging_name" --template-file "$azure_template_path_sql_database" --verbose --parameters \
location="$azure_region" server_name="$azure_sql_server_name" db_name="$azure_sql_db_tx_staging_name" \
db_sku="$azure_sql_db_tx_staging_sku" db_tier="$azure_sql_db_tx_staging_tier" db_max_size_bytes="$azure_sql_db_tx_staging_max_size_bytes" \
db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$azure_storage_acct_name" audit_storage_account_key="$azure_storage_acct_key"

echo -e "\n"
echo "Deploy Tx Prod database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$azure_resource_group_name" -n "$azure_sql_db_tx_prod_name" --template-file "$azure_template_path_sql_database" --verbose --parameters \
location="$azure_region" server_name="$azure_sql_server_name" db_name="$azure_sql_db_tx_prod_name" \
db_sku="$azure_sql_db_tx_prod_sku" db_tier="$azure_sql_db_tx_prod_tier" db_max_size_bytes="$azure_sql_db_tx_prod_max_size_bytes" \
db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$azure_storage_acct_name" audit_storage_account_key="$azure_storage_acct_key"

echo -e "\n"
echo "Restore bacpac to Azure SQL ref database"
az sql db import -g "$azure_resource_group_name" -s "$azure_sql_server_name" -n "$azure_sql_db_ref_name" \
    -u "$azure_sql_server_admin_sql_username" -p "$azure_sql_server_admin_sql_password" \
    --storage-uri "$azure_sql_db_ref_bacpac_storage_uri" --storage-key "$azure_storage_acct_key" --storage-key-type "StorageAccessKey" --verbose

echo -e "\n"
echo "Restore bacpac to Azure SQL tx staging database"
az sql db import -g "$azure_resource_group_name" -s "$azure_sql_server_name" -n "$azure_sql_db_tx_staging_name" \
    -u "$azure_sql_server_admin_sql_username" -p "$azure_sql_server_admin_sql_password" \
    --storage-uri "$azure_sql_db_tx_staging_bacpac_storage_uri" --storage-key "$azure_storage_acct_key" --storage-key-type "StorageAccessKey" --verbose

echo -e "\n"
echo "Restore bacpac to Azure SQL tx prod database"
az sql db import -g "$azure_resource_group_name" -s "$azure_sql_server_name" -n "$azure_sql_db_tx_prod_name" \
    -u "$azure_sql_server_admin_sql_username" -p "$azure_sql_server_admin_sql_password" \
    --storage-uri "$azure_sql_db_tx_prod_bacpac_storage_uri" --storage-key "$azure_storage_acct_key" --storage-key-type "StorageAccessKey" --verbose


# Here for reference - don't need it for this deployment though as we're using service principals, not managed service identities
# azure_sql_server_fqdn="$(az sql server show -g "$azure_resource_group_name" -n "$azure_sql_server_name" -o tsv --query "fullyQualifiedDomainName")"
# echo $azure_sql_server_fqdn
# azure_sql_server_identity_principal_id="$(az sql server show -g "$azure_resource_group_name" -n "$azure_sql_server_name" -o tsv --query "identity.principalId")"
# echo $azure_sql_server_identity_principal_id

echo -e "\n"
echo "Creating ADF deploy scripts, steps 1 and 2."

echo -e "az group deployment create -g "$azure_resource_group_name" -n "$azure_adf_factory_name""-1" --template-file "$azure_template_path_adf_step1" --verbose --parameters \\
    location="$azure_region" factory_name="$azure_adf_factory_name" integration_runtime_name="$azure_adf_ir_name"" > $azure_adf_script_step1

echo -e "az group deployment create -g "$azure_resource_group_name" -n "$azure_adf_factory_name""-2" --template-file "$azure_template_path_adf_step2" --verbose --parameters \\
    location="$azure_region" factory_name="$azure_adf_factory_name" integration_runtime_name="$azure_adf_ir_name" \\
    azure_ad_tenant_id="$azure_aad_tenant_id" azure_service_principal_id="$azure_sp_app_client_id" azure_service_principal_key="$azure_sp_password" \\
    azure_storage_account_name="$azure_storage_acct_name" azure_container_name_staging_ref="$azure_container_name_staging_ref" azure_container_name_staging_tx="$azure_container_name_staging_tx" \\
    azure_sql_server_name_ref_data="$azure_sql_server_name" azure_sql_database_name_ref_data="$azure_sql_db_ref_name" \\
    azure_sql_server_name_tx_prod_data="$azure_sql_server_name" azure_sql_database_name_tx_prod_data="$azure_sql_db_tx_prod_name" \\
    azure_sql_server_name_tx_staging_data="$azure_sql_server_name" azure_sql_database_name_tx_staging_data="$azure_sql_db_tx_staging_name" \\
    on_prem_sql_server_name_ref_data="$on_prem_sql_server_ref_name" on_prem_sql_database_name_ref_data="$on_prem_sql_db_ref_name" \\
    on_prem_sql_server_name_tx_data="$on_prem_sql_server_tx_name" on_prem_sql_database_name_tx_data="$on_prem_sql_db_tx_name" \\
    on_prem_sql_username_ref_data="$on_prem_sql_username" on_prem_sql_password_ref_data="$on_prem_sql_password" \\
    on_prem_sql_username_tx_data="$on_prem_sql_username" on_prem_sql_password_tx_data="$on_prem_sql_password"" > $azure_adf_script_step2

echo -e "\n"
echo "Creating Azure Logic App and API Connection deploy script. The Azure Data Factory must be completely deployed before this can be deployed."

# This next echo statement is a bit complex, but it generates a .sh file that first creates an API connection to ADF,
# then creates a Logic App whose only step is to invoke an ADF pipeline using that ADF connection. However,
# the Logic App itself must be "invokeable" by other things to kick off that ADF pipeline.
# Lastly, the generated script will echo to the console the exact Logic App URL to invoke (via POST, not GET) to kick off the ADF pipeline!
echo -e " \
az group deployment create -g $azure_resource_group_name -n $azure_logic_app_name --template-file $azure_template_path_api_connection --verbose --parameters \\
    location=$azure_region azure_api_connection_name=$azure_api_connection_name \\
    azure_ad_tenant_id=$azure_aad_tenant_id azure_service_principal_id=$azure_sp_app_client_id azure_service_principal_key=$azure_sp_password

logic_app_url=\"\$(az group deployment create -g $azure_resource_group_name -n $azure_logic_app_name --template-file $azure_template_path_logic_app -o tsv --query "properties.outputs.logic_app_url.value" --verbose --parameters \\
    location=$azure_region azure_logic_app_name=$azure_logic_app_name azure_adf_factory_name=$azure_adf_factory_name \\
    azure_adf_pipeline_name=$azure_adf_pipeline_name azure_api_connection_name=$azure_api_connection_name)\"

echo \$logic_app_url" > $azure_api_connection_and_logic_app_script



echo -e "\n"

echo "1. Connect to EACH of the Azure SQL DB databases, using the AD credential you used for virtual SQL Server above, and run the following SQL statements in EACH database"
echo "CREATE USER [""$azure_sp_display_name""] FROM EXTERNAL PROVIDER;"
echo "ALTER ROLE [""$azure_sql_security_adf_role_name""] ADD MEMBER [""$azure_sp_display_name""];"

echo -e "\n"
echo "2. Next, run"
echo "$azure_adf_script_step1"
echo "This will create the new ADF and a Self-Hosted Integration Runtime (SHIR), only."

echo -e "\n"
echo "3. Retrieve the new ADF SHIR authentication key and configure at least one on-premise SHIR node to communicate to the new SHIR. See README for details on how to do this."

echo -e "\n"
echo "4. Next, run"
echo "$azure_adf_script_step2"
echo "This will create all ADF pipelines, datasets, and activities. The SHIR must be correctly configured with at least one on-premise node before running this!"

echo -e "\n"
echo "5. Next, run"
echo "$azure_api_connection_and_logic_app_script"
echo "This will create an Azure Logic App and an Azure API Connection to enable the Logic App to invoke an Azure Data Factory Pipeline."
echo "The API Connection uses the Service Principal used elsewhere in this deployment to authenticate to the Azure Data Factory."
echo "When completed, this script will echo to the console the exact URL to use to invoke this new Logic App and have it kick off the specified ADF pipeline."

# ##################################################
