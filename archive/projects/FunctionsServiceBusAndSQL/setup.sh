#!/bin/bash

# Login to Azure
az login

# #####
# Variables

# Naming prefix - change as you like. Has no functional purpose.
prefix="tst"

azure_aad_tenant_id="$(az account show -o tsv --query "tenantId")"

azure_subscription_id="$(az account show -o tsv --query "id")"

azure_region="eastus"

azure_external_ips_allowed="PROVIDE"

# Get email address for alerts - here just use signed-in user's email address
azure_alerts_email_address="$(az ad signed-in-user show -o tsv --query "mail")"

resource_group_name="$prefix"

storage_acct_name="$prefix""testsa"
storage_acct_key="DO NOT SET - SCRIPT ASSIGNS VALUE"
storage_container_source="source"
storage_container_target="target"
storage_container_assets="assets"
storage_container_archive="archive"
storage_container_unprocessed="unprocessed"

service_bus_namespace_name="$prefix""testns"
service_bus_sku="Standard"
service_bus_namespace_access_policy_name="ListenSend"
service_bus_topic_name="$prefix""testtp"
service_bus_topic_subscription_name="$prefix""testtpsub"

app_insights_name="$prefix""ai"
app_insights_key="DO NOT SET - SCRIPT ASSIGNS VALUE"

app_service_plan_name="$prefix""asp"
app_service_plan_sku="S1"

functionapp_name="$prefix""fn"
functionapp_msi_role="Contributor"
functionapp_msi_principal_id="DO NOT SET - SCRIPT ASSIGNS VALUE"

# Function App MSI scope and role specific to storage
functionapp_msi_scope_storage="/subscriptions/""$azure_subscription_id""/resourceGroups/""$resource_group_name""/providers/Microsoft.Storage/storageAccounts/""$storage_acct_name"
functionapp_msi_role_storage="Storage Blob Data Contributor"

# Assemble RG-level MSI scope (this makes individual resource scope assignments superfluous)
# NOTE this is NOT used below, since its scope spans the entire resource group. It's here for your reference.
# We use more restrictive scopes below.
# functionapp_msi_scope="/subscriptions/""$azure_subscription_id""/resourceGroups/""$resource_group_name"

key_vault_name="$prefix""kv"

# Azure SQL
azure_sql_server_admin_sql_username="$prefix""-sqladmin"
azure_sql_server_admin_sql_password="PROVIDE"

# Get display name and principal ID for Azure SQL AAD admin - use the logged-in user (alter this if needed)
azure_sql_server_admin_aad_display_name="$(az ad signed-in-user show -o tsv --query "displayName")"
azure_sql_server_admin_aad_principal_id="$(az ad signed-in-user show -o tsv --query "objectId")"

azure_template_path_sql_server="azuresqlserver.template.json"
azure_sql_server_name="$prefix""-sql-""$azure_region"

azure_template_path_sql_database="azuresqldb.template.json"

azure_sql_db_name="testdb1"
azure_sql_db_sku="S0"
azure_sql_db_tier="Standard"
azure_sql_db_max_size_bytes=268435456000
azure_sql_db_bacpac_file="testdb1.bacpac"
azure_sql_db_bacpac_path="./$azure_sql_db_bacpac_file"
azure_sql_db_bacpac_storage_uri="https://""$storage_acct_name"".blob.core.windows.net/""$storage_container_assets""/""$azure_sql_db_bacpac_file"

azure_sql_security_role_name="TestRole"  # This MUST match what's in the bacpac/database! Do not change this until/unless you know exactly what you're doing and have changed it in those other places!!!

# #####

# #####
# Operations

# https://docs.microsoft.com/en-us/cli/azure/group
# Create new resource group
echo "Create Resource Group"
az group create -l $azure_region -n $resource_group_name

# https://docs.microsoft.com/en-us/cli/azure/storage/account
# Create storage account
echo "Create Storage Account"
az storage account create -l $azure_region -g $resource_group_name -n $storage_acct_name --kind StorageV2 --sku Standard_LRS

# List storage account keys (need a key for container create)
# az storage account keys list -n $storage_acct_name -g $resource_group_name
echo "Get Storage Account key"
storage_acct_key="$(az storage account keys list -g "$resource_group_name" -n "$storage_acct_name" -o tsv --query "[0].value")"

# https://docs.microsoft.com/en-us/cli/azure/storage/container
# Create containers in storage account
echo "Create Storage Containers"
az storage container create -n $storage_container_source --account-name $storage_acct_name --account-key $storage_acct_key
az storage container create -n $storage_container_target --account-name $storage_acct_name --account-key $storage_acct_key
az storage container create -n $storage_container_assets --account-name $storage_acct_name --account-key $storage_acct_key
az storage container create -n $storage_container_archive --account-name $storage_acct_name --account-key $storage_acct_key
az storage container create -n $storage_container_unprocessed --account-name $storage_acct_name --account-key $storage_acct_key

# https://docs.microsoft.com/en-us/cli/azure/servicebus/namespace
# Create service bus namespace
echo "Create Service Bus Namespace"
az servicebus namespace create  -l $azure_region -g $resource_group_name -n $service_bus_namespace_name --sku $service_bus_sku

# https://docs.microsoft.com/en-us/cli/azure/servicebus/namespace/authorization-rule
# Create service bus namespace authorization rule
echo "Create Service Bus Namespace authorization rule"
az servicebus namespace authorization-rule create -g $resource_group_name --namespace-name $service_bus_namespace_name -n $service_bus_namespace_access_policy_name --rights Listen Send

# https://docs.microsoft.com/en-us/cli/azure/servicebus/topic
# Create service bus topic
echo "Create Service Bus Topic"
az servicebus topic create -g $resource_group_name --namespace-name $service_bus_namespace_name -n $service_bus_topic_name

# https://docs.microsoft.com/en-us/cli/azure/servicebus/topic/subscription
# Create service bus topic subscription
echo "Create Service Bus Topic Subscription"
az servicebus topic subscription create -g $resource_group_name --namespace-name $service_bus_namespace_name --topic-name $service_bus_topic_name -n $service_bus_topic_subscription_name

# https://docs.microsoft.com/en-us/cli/azure/appservice/plan
# Create app service plan
echo "Create App Service Plan"
az appservice plan create -l $azure_region -g $resource_group_name -n $app_service_plan_name --sku $app_service_plan_sku

# https://docs.microsoft.com/en-us/cli/azure/group/deployment
# Create application insights instance and get instrumentation key
echo "Create Application Insights and get Instrumentation Key"
app_insights_key="$(az group deployment create -g $resource_group_name -n $app_insights_name --template-file "app_insights.template.json" \
  -o tsv --query "properties.outputs.app_insights_instrumentation_key.value" \
  --parameters location="$azure_region" instance_name="$app_insights_name")"

# https://docs.microsoft.com/en-us/cli/azure/functionapp
# Create function app with plan and app insights created above
# Using Windows at this point because MSI on Linux still in preview
echo "Create Function App and link to App Service Plan and App Insights instance created above"
az functionapp create -g $resource_group_name -n $functionapp_name --storage-account $storage_acct_name \
  --app-insights $app_insights_name --app-insights-key $app_insights_key \
  --plan $app_service_plan_name --os-type Windows --runtime dotnet

# https://docs.microsoft.com/en-us/cli/azure/functionapp/identity
# Assign managed identity to function app
# Omit scope assignment for least privilege, assign explicit access below for storage, key vault, SQL
#  --scope $functionapp_msi_scope
echo "Assign managed identity to function app"
functionapp_msi_principal_id="$(az functionapp identity assign -g $resource_group_name -n $functionapp_name --role $functionapp_msi_role -o tsv --query "principalId")"
echo $functionapp_msi_principal_id

# echo "Sleep to allow MSI identity to finish provisioning"
sleep 120s

# Get managed identity principal and tenant ID
# az functionapp identity show -g $resource_group_name -n $functionapp_name
echo "Get Function App identity Principal ID and Display Name"
# functionapp_msi_principal_id="$(az functionapp identity show -g $resource_group_name -n $functionapp_name -o tsv --query "principalId")"
functionapp_msi_display_name="$(az ad sp show --id $functionapp_msi_principal_id -o tsv --query "displayName")"

# Assign Function App MSI rights to storage
echo "Assign MSI principal rights to read/write data to storage account (this is redundant with RG Contributor, but OK to do and needed if the storage acct is in another RG)"
az role assignment create --scope "$functionapp_msi_scope_storage" --assignee-object-id "$functionapp_msi_principal_id" --role "$functionapp_msi_role_storage"

# https://docs.microsoft.com/en-us/cli/azure/keyvault
# Create key vault
echo "Create Azure Key Vault"
az keyvault create -l $azure_region -g $resource_group_name -n $key_vault_name

echo "Assign the Function App MSI access to the key vault"
az keyvault set-policy -g $resource_group_name -n $key_vault_name --object-id $functionapp_msi_principal_id --secret-permissions get

echo "Upload bacpac file to import into Azure SQL database"
az storage blob upload --account-name "$storage_acct_name" --account-key "$storage_acct_key" -c "$storage_container_assets" -n "$azure_sql_db_bacpac_file" -f "$azure_sql_db_bacpac_path"

echo "Create Azure SQL virtual server"
az group deployment create -g "$resource_group_name" -n "$azure_sql_server_name" --template-file "$azure_template_path_sql_server" --parameters \
location="$azure_region" server_name="$azure_sql_server_name" server_admin_username="$azure_sql_server_admin_sql_username" server_admin_password="$azure_sql_server_admin_sql_password" \
alerts_email_address="$azure_alerts_email_address" audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key" \
firewall_rule_start_ip="$azure_external_ips_allowed" firewall_rule_end_ip="$azure_external_ips_allowed"

echo "Configure Azure SQL virtual server AD Admin"
az sql server ad-admin create -g "$resource_group_name" -s "$azure_sql_server_name" -u "$azure_sql_server_admin_aad_display_name" -i "$azure_sql_server_admin_aad_principal_id"

echo "Deploy database (read scale-out and zone redundancy only available for Azure SQL DB Premium)"
az group deployment create -g "$resource_group_name" -n "$azure_sql_db_name" --template-file "$azure_template_path_sql_database" --parameters \
location="$azure_region" server_name="$azure_sql_server_name" db_name="$azure_sql_db_name" \
db_sku="$azure_sql_db_sku" db_tier="$azure_sql_db_tier" db_max_size_bytes="$azure_sql_db_max_size_bytes" \
db_read_scale="Disabled" db_zone_redundant=false audit_storage_account_name="$storage_acct_name" audit_storage_account_key="$storage_acct_key"

echo "Restore bacpac to Azure SQL ref database"
az sql db import -g "$resource_group_name" -s "$azure_sql_server_name" -n "$azure_sql_db_name" \
    -u "$azure_sql_server_admin_sql_username" -p "$azure_sql_server_admin_sql_password" \
    --storage-uri "$azure_sql_db_bacpac_storage_uri" --storage-key "$storage_acct_key" --storage-key-type "StorageAccessKey"

# #####

echo -e "\n"

echo "Now connect to the Azure SQL DB database, using the AD credential used for virtual SQL Server above, and run the following SQL statements to add the Azure Function's MSI to the database and specified role."
echo "CREATE USER [""$functionapp_msi_display_name""] FROM EXTERNAL PROVIDER;"
echo "ALTER ROLE [""$azure_sql_security_role_name""] ADD MEMBER [""$functionapp_msi_display_name""];"
