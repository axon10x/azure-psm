#!/bin/bash

# Login first
# az login

# #####
# Variables

azure_region="eastus"
resource_group_name="vmenv"

deployment_name="VM"
azure_template_file_path="azuredeploy.template.json"
azure_parameters_file_path="@azuredeploy.parameters.ubuntu.json"


# https://docs.microsoft.com/en-us/cli/azure/group
# Create new resource group
# echo "Create Resource Group"
# az group create -l $azure_region -n $resource_group_name

# ARM deployment

# Uncomment next line to only validate the deployment - this does NOT do the actual deployment, but will only flag any template/parameter errors
# az group deployment validate -g "$resource_group_name" --template-file "$azure_template_file_path" --parameters "$azure_parameters_file_path" --verbose

# Uncomment next line to perform the deployment
az deployment group create -g "$resource_group_name" -n "$deployment_name" --template-file "$azure_template_file_path" --parameters "$azure_parameters_file_path" --verbose
