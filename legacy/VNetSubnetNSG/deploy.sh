#!/bin/bash

# Login first
# az login

# #####
# Variables

prefix="i1"
resource_group_name="rg""$prefix"
azure_region="eastus"
vnet_name="$prefix""vnet1"
vnet_address_space="10.0.0.0/16"
subnet_name="$prefix""subnet1"
subnet_address_space="10.0.1.0/24"
nsg_name="$prefix""nsg1"
nsg_rule_name="inbound1"
nsg_rule_priority=100
azure_external_ips_allowed=""
deployment_name="VNetSubnetNSG"
azure_template_file_path="azuredeploy.template.json"

# https://docs.microsoft.com/en-us/cli/azure/group
# Create new resource group
echo "Create Resource Group"
az group create -l $azure_region -n $resource_group_name

# ARM deployment
echo "Deploy VNet, subnet, NSG via ARM template/parameters files"

# az group deployment validate -g "$resource_group_name" --verbose --template-file "$azure_template_file_path" --parameters  \
# 	location="$azure_region" vnet_name="$vnet_name" vnet_address_space="$vnet_address_space" subnet_name="$subnet_name" subnet_address_space="$subnet_address_space" \
# 	nsg_name="$nsg_name" nsg_rule_name="$nsg_rule_name" nsg_rule_source="$azure_external_ips_allowed" nsg_rule_priority="$nsg_rule_priority"

az group deployment create -g "$resource_group_name" -n "$deployment_name" --verbose --template-file "$azure_template_file_path" --parameters \
	location="$azure_region" vnet_name="$vnet_name" vnet_address_space="$vnet_address_space" subnet_name="$subnet_name" subnet_address_space="$subnet_address_space" \
	nsg_name="$nsg_name" nsg_rule_name="$nsg_rule_name" nsg_rule_source="$azure_external_ips_allowed" nsg_rule_priority="$nsg_rule_priority"
