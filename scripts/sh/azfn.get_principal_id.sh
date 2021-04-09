#!/bin/bash

# Get an Azure Function App's MSI or SP ID

subscription_id=""
resource_group_name=""
fn_app_name=""

az functionapp show --subscription "$subscription_id" -g "$resource_group_name" -n "$fn_app_name"

principal_id="$(az functionapp show --subscription "$subscription_id" -g "$resource_group_name" -n "$fn_app_name" -o tsv --query "identity.principalId")"

echo $principal_id

az ad sp show $principal_id

