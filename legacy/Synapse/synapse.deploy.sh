#!/bin/bash

# ====================
# Variables

location="eastus"
resource_group_name="test-synapse-pz"

subscription_id="$(az account show -o tsv --query "id")"

template_file="synapse.deploy.json"
deployment_name="deploy_synapse"
# ====================

# Operations

echo "Create Resource Group"
az group create --subscription "$subscription_id" -n "$resource_group_name" -l "$location"

echo -e "\n"

echo "Deploy template"
az group deployment create --subscription "$subscription_id" \
	-g "$resource_group_name" -n "$deployment_name" --template-file "$template_file" \
	--parameters location="$location" --verbose

# ====================
