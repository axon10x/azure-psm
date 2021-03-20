#!/bin/bash

# ====================
# Variables

name_infix="pz"

resource_group_name="vms"
location="eastus"
external_ips_allowed="PROVIDE"

# Security
subscription_id="$(az account show -o tsv --query "id")"
aad_tenant_id="$(az account show -o tsv --query "tenantId")"

# User-Assigned Managed Identity
create_uai=true
# If using an existing Managed Identity - i.e. create_uai=false - provide its Principal ID (objectId) here
mi_principal_id=""
mi_template_file="mi.template.json"
mi_name="$name_infix""-uai"

# Storage
storage_template_file="storage.template.json"
storage_account_name="$name_infix""sa"
storage_account_sku="Standard_LRS"
storage_account_tier="Standard"
storage_access_tier="Hot"
storage_container_name="assets"

# NSGs
nsg_template_file="nsg.template.json"
nsg_name="$name_infix""-nsg"

# VNet
vnet_template_file="vnet.template.json"
vnet_name="$name_infix""-vnet"
vnet_address_space="10.0.0.0/16"
enable_vm_protection="true"

# Subnets
subnet_template_file="subnet.template.json"
subnet_name="subnet1"
subnet_address_space="10.0.1.0/24"

# Managed identity storage account access
msi_role_template_file="role-assignment.template.json"
msi_role_name_storage_acct_contrib="Storage Account Contributor"
msi_role_id_storage_acct_contrib="$(az role definition list --custom-role-only false -o tsv --query "[?roleName=='$msi_role_name_storage_acct_contrib'].id")"

# NIC
nic_template_file="nic.template.json"
private_ip_allocation_method="Dynamic"

# Public IP
public_ip_type="Static"
public_ip_sku="Standard"

# Linux VM
create_vm_linux=true
vm_l_template_file="vm.linux.template.json"
vm_l_name="$name_infix""-vm-l"
vm_l_os_publisher="Canonical"
vm_l_os_offer="UbuntuServer"
vm_l_os_sku="19.04"
vm_l_admin_username="PROVIDE"
vm_l_admin_public_key="ssh-rsa PROVIDE== ""$vm_l_admin_username"
vm_l_size="Standard_D4s_v3"
vm_l_enable_accelerated_networking=true
vm_l_disk1_size=32
vm_l_nic_name="$vm_l_name""-nic"
vm_l_public_ip_name="$vm_l_name""-pip"

# Windows 10 VM
create_vm_windows=false
vm_w_template_file="vm.win10.template.json"
vm_w_name="$name_infix""-vm-w"
vm_w_os_publisher="MicrosoftWindowsDesktop"
vm_w_os_offer="Windows-10"
vm_w_os_sku="19h2-entn"
vm_w_admin_username="PROVIDE"
vm_w_admin_password="PROVIDE"
vm_w_size="Standard_D4s_v3"
vm_w_enable_accelerated_networking=true
vm_w_disk1_size=32
vm_w_nic_name="$vm_w_name""-nic"
vm_w_public_ip_name="$vm_w_name""-pip"

# ====================
# Operations

echo "Create Resource Group"
az group create -n $resource_group_name -l $location

echo -e "\n"

echo "Create public NSG"
az group deployment create -g "$resource_group_name" -n "$nsg_name" --template-file "$nsg_template_file" --verbose --parameters \
	location="$location" nsg_name="$nsg_name" external_ips_allowed="$external_ips_allowed"

echo -e "\n"

echo "Create VNet"
az group deployment create -g "$resource_group_name" -n "$vnet_name" --template-file "$vnet_template_file" --verbose --parameters \
	location="$location" vnet_name="$vnet_name" vnet_address_space="$vnet_address_space" enable_vm_protection="$enable_vm_protection"

echo "Create public subnet"
az group deployment create -g "$resource_group_name" -n "$subnet_name" --template-file "$subnet_template_file" --verbose --parameters \
	location="$location" vnet_name="$vnet_name" subnet_name="$subnet_name" subnet_address_space="$subnet_address_space" nsg_name="$nsg_name"

echo "Create storage account"
az group deployment create -g "$resource_group_name" -n "storage_account" --template-file "$storage_template_file" --verbose -o tsv --query "properties.outputs.storage_account_name.value" --parameters \
	location="$location" storage_account_name="$storage_account_name" storage_account_name_infix="" storage_account_sku="$storage_account_sku" \
	storage_account_tier="$storage_account_tier" storage_access_tier="$storage_access_tier" \
	vnet_name="$vnet_name" subnet_name="$subnet_name" external_ips_allowed="$external_ips_allowed"

echo "Get storage account URL"
# INLINE VARIABLE INITIALIZATION
storage_base_url="https://""$storage_account_name"".blob.core.windows.net"

echo "Prepare MSI scope for storage access"
# INLINE VARIABLE INITIALIZATION
msi_scope_storage="/subscriptions/""$subscription_id""/resourceGroups/""$resource_group_name""/providers/Microsoft.Storage/storageAccounts/""$storage_account_name"

echo "Get storage account key"
# INLINE VARIABLE INITIALIZATION
storage_acct_key="$(az storage account keys list -g "$resource_group_name" -n "$storage_account_name" -o tsv --query "[0].value")"

echo "Create storage container"
# az storage container create --account-name "$storage_account_name" --account-key "$storage_acct_key" -n "$storage_container_name" --verbose

echo -e "\n"

if [ true = $create_uai ]
then
	echo "Create User Assigned Managed Identity"
	# INLINE VARIABLE INITIALIZATION
	mi_principal_id="$(az group deployment create -g "$resource_group_name" -n "mi_name" --template-file "$mi_template_file" --verbose -o tsv --query "properties.outputs.principal_id.value" --parameters tenant_id="$aad_tenant_id" location="$location" mi_name="$mi_name")"
	echo "Sleep to wait for MI to finish provisioning..."
	sleep 120s
fi

# INLINE VARIABLE INITIALIZATION
mi_client_id="$(az ad sp show --id $mi_principal_id -o tsv --query "appId")"
echo "Managed Identity Principal ID: ""$mi_principal_id"
echo "Managed Identity Client ID: ""$mi_client_id"

echo -e "\n"

echo "Assign Managed Identity rights to read/write data to storage account"
az role assignment create --scope "$msi_scope_storage" --assignee-object-id "$mi_principal_id" --role "$msi_role_name_storage_acct_contrib"
az group deployment create -g "$resource_group_name" -n "role-assignment-storage" --template-file "$msi_role_template_file" --verbose --parameters \
	role_definition_id="$msi_role_id_storage_acct_contrib" principal_id="$mi_principal_id"

echo -e "\n"

if [ true = $create_vm_linux ]
then
	echo "Create Linux VM"
	echo "Create NIC ""$vm_l_nic_name"
	az group deployment create -g "$resource_group_name" -n "$vm_l_nic_name" --template-file "$nic_template_file" --verbose --parameters \
		location="$location" nic_name="$vm_l_nic_name" vnet_name="$vnet_name" subnet_name="$subnet_name" \
		enable_accelerated_networking="$vm_l_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method" \
		public_ip_name="$vm_l_public_ip_name" public_ip_type="$public_ip_type" public_ip_sku="$public_ip_sku"

	echo "Create VM ""$vm_l_name"
	az group deployment create -g "$resource_group_name" -n "$vm_l_name" --template-file "$vm_l_template_file" --verbose --parameters \
		location="$location" nic_name="$vm_l_nic_name" \
		os_publisher="$vm_l_os_publisher" os_offer="$vm_l_os_offer" os_sku="$vm_l_os_sku" \
		vm_name="$vm_l_name" vm_size="$vm_l_size" \
		admin_username="$vm_l_admin_username" admin_public_key="$vm_l_admin_public_key" \
		data_disk_1_size_in_gb="$vm_l_disk1_size" mi_name="$mi_name" 
fi

echo -e "\n"

if [ true = $create_vm_windows ]
then
	echo "Create Win10 VM"
	echo "Create NIC ""$vm_w_nic_name"
	az group deployment create -g "$resource_group_name" -n "$vm_w_nic_name" --template-file "$nic_template_file" --verbose --parameters \
		location="$location" nic_name="$vm_w_nic_name" vnet_name="$vnet_name" subnet_name="$subnet_name" \
		enable_accelerated_networking="$vm_w_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method" \
		public_ip_name="$vm_w_public_ip_name" public_ip_type="$public_ip_type" public_ip_sku="$public_ip_sku"

	echo "Create VM ""$vm_w_name"
	az group deployment create -g "$resource_group_name" -n "$vm_w_name" --template-file "$vm_w_template_file" --verbose --parameters \
		location="$location" nic_name="$vm_w_nic_name" \
		os_publisher="$vm_w_os_publisher" os_offer="$vm_w_os_offer" os_sku="$vm_w_os_sku" \
		vm_name="$vm_w_name" vm_size="$vm_w_size" \
		admin_username="$vm_w_admin_username" admin_password="$vm_w_admin_password" \
		data_disk_1_size_in_gb="$vm_w_disk1_size" mi_name="$mi_name" 
fi