#!/bin/bash

echo "Starting: ""`date`"

##########
### YOU MUST REPLACE "PROVIDE" placeholders with real values!
##########

# ====================
# Variables
# Name infix - provide a 3- or 4-character unique-ish string
name_infix="PROVIDE"

resource_group_name="$name_infix"
external_ips_allowed="PROVIDE"

# Location2 will used e.g. for redundant storage account service endpoints. TBD how to get a primary region pair programmatically. az account list-locations does not do so.
location="eastus"
location2="westus"

# Availability Zones
azmin=1
azmax=3

# Security
subscription_id="$(az account show -o tsv --query "id")"
aad_tenant_id="$(az account show -o tsv --query "tenantId")"

# User-Assigned Managed Identity
mi_template_file="mi.template.json"
mi_name="$name_infix""-uai"

# Storage Account
storage_template_file="storage.template.json"
storage_account_sku="Standard_RAGZRS"
storage_account_tier="Standard"
storage_access_tier="Hot"
storage_container_name_deploy="deploy"

local_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vm_script_file_name="vm.sh"
vm_script_file_path="$local_path""/vm_scripts/""$vm_script_file_name"

# Storage Account for Diagnostics
storage_diag_template_file="storage.diag.template.json"

# NSGs
public_nsg_template_file="nsg.public.template.json"
public_nsg_name="$name_infix""-public-nsg"
private_nsg_template_file="nsg.private.template.json"
private_nsg_name="$name_infix""-private-nsg"
appgw_nsg_template_file="nsg.appgw.template.json"
appgw_nsg_name="$name_infix""-appgw-nsg"
lb_nsg_template_file="nsg.lb.template.json"
lb_nsg_name="$name_infix""-lb-nsg"

# Service Endpoint Policy
sep_template_file="sep.template.json"
sep_name="$name_infix""-sep"
sep_service="Microsoft.Storage"

# VNet
vnet_template_file="vnet.template.json"
vnet_name="$name_infix""-vnet"
vnet_address_space="10.0.0.0/16"
enable_vm_protection="true"

# Subnets
subnet_template_file="subnet.template.json"
subnet_sep_template_file="subnet.sep.template.json"
public_subnet_name="public-subnet"
public_subnet_address_space="10.0.1.0/24"
private_subnet_name="private-subnet"
private_subnet_address_space="10.0.32.0/24"
appgw_subnet_name="appgw-subnet"
appgw_subnet_address_space="10.0.251.0/24"
lb_subnet_name="lb-subnet"
lb_subnet_address_space="10.0.252.0/24"

# NIC
nic_private_template_file="nic.private.template.json"
nic_public_template_file="nic.public.template.json"
private_ip_allocation_method="Dynamic"
public_ip_type="Static"
public_ip_sku="Standard"

# VMs
vm_sai_template_file="vm.sai.template.json"
vm_uai_template_file="vm.uai.template.json"
vm_os_publisher="OpenLogic"
vm_os_offer="CentOS"
vm_os_sku="8.0"
vm_admin_username="PROVIDE"
vm_admin_public_key="ssh-rsa PROVIDE== ""$vm_admin_username"

# VMs - Public subnet, Gate VM
gate_vm_size="Standard_D2s_v3"
gate_vm_count_per_avl_zone=2
gate_vm_enable_accelerated_networking=false
gate_vm_disk1_size=64
gate_vm_disk2_size=64
gate_vm_fqdns=""
gate_vm_autoshutdown=true

# VMs - Private subnet, Server VM
server_vm_size="Standard_D2s_v3"
server_vm_count_per_avl_zone=2
server_vm_enable_accelerated_networking=false
server_vm_disk1_size=64
server_vm_disk2_size=128
server_vm_autoshutdown=true

# VMs - Private subnet, Data VM
data_vm_size="Standard_D2s_v3"
data_vm_count_per_avl_zone=2
data_vm_enable_accelerated_networking=false
data_vm_disk1_size=64
data_vm_disk2_size=128
data_vm_autoshutdown=true

# VMs - Private subnet, Search VM
search_vm_size="Standard_D2s_v3"
search_vm_count_per_avl_zone=2
search_vm_enable_accelerated_networking=false
search_vm_disk1_size=128
search_vm_disk2_size=4096
search_vm_autoshutdown=true

# VM Auto Shutdown
autoshutdown_template_file="autoshutdown.template.json"
autoshutdown_time="0300"
autoshutdown_timezone="UTC"
autoshutdown_notification_state="Enabled"
autoshutdown_notification_minutes_before=15
autoshutdown_notification_webhook_url="PROVIDE"
autoshutdown_notification_email="PROVIDE"
autoshutdown_notification_locale="en"

# Managed identity storage account access
msi_role_template_file="role-assignment.template.json"
msi_role_name_storage_blob_contrib="Storage Blob Data Contributor"
msi_role_name_storage_acct_contrib="Storage Account Contributor"
msi_role_id_storage_blob_contrib="$(az role definition list --custom-role-only false -o tsv --query "[?roleName=='$msi_role_name_storage_blob_contrib'].id")"
msi_role_id_storage_acct_contrib="$(az role definition list --custom-role-only false -o tsv --query "[?roleName=='$msi_role_name_storage_acct_contrib'].id")"

# App Gateway
appgw_template_file="appgw.template.json"
appgw_name="$name_infix""-appgw"
appgw_public_ip_name="$appgw_name""-pip"
appgw_sku_name="Standard_v2"
appgw_sku_tier="Standard_v2"
appgw_enable_http2=false
appgw_autoscale_instances_min=1
appgw_autoscale_instances_max=5
appgw_back_end_pool_name="$appgw_name""-pool"

# Load Balancer
lb_template_file="lb.template.json"
lb_name="$name_infix""-lb"
lb_back_end_pool_name="$lb_name""-pool"

# --------------------
# ====================


# ====================
# Operations

echo "Create Resource Group"
az group create -n $resource_group_name -l $location

echo -e "\n"

echo "Create public NSG"
az group deployment create -g "$resource_group_name" -n "$public_nsg_name" --template-file "$public_nsg_template_file" --verbose --parameters \
  location="$location" nsg_name="$public_nsg_name" external_ips_allowed="$external_ips_allowed"

echo "Create private NSG"
az group deployment create -g "$resource_group_name" -n "$private_nsg_name" --template-file "$private_nsg_template_file" --verbose --parameters \
  location="$location" nsg_name="$private_nsg_name"

echo "Create app GW NSG"
az group deployment create -g "$resource_group_name" -n "$appgw_nsg_name" --template-file "$appgw_nsg_template_file" --verbose --parameters \
  location="$location" nsg_name="$appgw_nsg_name" external_ips_allowed="$external_ips_allowed"

echo "Create LB NSG"
az group deployment create -g "$resource_group_name" -n "$lb_nsg_name" --template-file "$lb_nsg_template_file" --verbose --parameters \
  location="$location" nsg_name="$lb_nsg_name" external_ips_allowed="$external_ips_allowed"

echo -e "\n"

echo "Create Service Endpoint Policy to limit access to storage in same resource group, i.e. prevent data exfiltration"
az group deployment create -g "$resource_group_name" -n "$sep_name" --template-file "$sep_template_file" --verbose --parameters \
  location="$location" sep_name="$sep_name" service="$sep_service"

echo -e "\n"

echo "Create VNet"
az group deployment create -g "$resource_group_name" -n "$vnet_name" --template-file "$vnet_template_file" --verbose --parameters \
  location="$location" vnet_name="$vnet_name" vnet_address_space="$vnet_address_space" enable_vm_protection="$enable_vm_protection"

echo "Create public subnet with Service Endpoint Policy"
az group deployment create -g "$resource_group_name" -n "$public_subnet_name" --template-file "$subnet_sep_template_file" --verbose --parameters \
  location="$location" location2="$location2" \
  vnet_name="$vnet_name" subnet_name="$public_subnet_name" subnet_address_space="$public_subnet_address_space" \
  nsg_name="$public_nsg_name" service="$sep_service" sep_name="$sep_name"

echo "Create private subnet with Service Endpoint Policy"
az group deployment create -g "$resource_group_name" -n "$private_subnet_name" --template-file "$subnet_sep_template_file" --verbose --parameters \
  location="$location" location2="$location2" \
  vnet_name="$vnet_name" subnet_name="$private_subnet_name" subnet_address_space="$private_subnet_address_space" \
  nsg_name="$private_nsg_name" service="$sep_service" sep_name="$sep_name"

echo "Create app GW subnet"
az group deployment create -g "$resource_group_name" -n "$appgw_subnet_name" --template-file "$subnet_template_file" --verbose --parameters \
  location="$location" location2="$location2" \
  vnet_name="$vnet_name" subnet_name="$appgw_subnet_name" subnet_address_space="$appgw_subnet_address_space" \
  nsg_name="$appgw_nsg_name" service="$sep_service"

echo "Create LB subnet"
az group deployment create -g "$resource_group_name" -n "$lb_subnet_name" --template-file "$subnet_template_file" --verbose --parameters \
  location="$location" location2="$location2" \
  vnet_name="$vnet_name" subnet_name="$lb_subnet_name" subnet_address_space="$lb_subnet_address_space" \
  nsg_name="$lb_nsg_name" service="$sep_service"

echo -e "\n"

echo "Create diagnostics storage account"
# INLINE VARIABLE INITIALIZATION
storage_account_diag_name="$(az group deployment create -g "$resource_group_name" -n "storage_account_diagnostics" --template-file "$storage_diag_template_file" --verbose -o tsv --query "properties.outputs.storage_account_name.value" --parameters \
  location="$location" storage_account_name_infix="$name_infix" vnet_name="$vnet_name" \
  subnet_name_public="$public_subnet_name" subnet_name_private="$private_subnet_name" subnet_name_appgw="$appgw_subnet_name" subnet_name_lb="$lb_subnet_name" \
  external_ips_allowed="$external_ips_allowed")"

echo "Get diagnostics storage account key"
# INLINE VARIABLE INITIALIZATION
storage_account_diag_key="$(az storage account keys list -g "$resource_group_name" -n "$storage_account_diag_name" -o tsv --query "[0].value")"

echo -e "\n"

echo "Create storage account"
# INLINE VARIABLE INITIALIZATION
storage_account_name="$(az group deployment create -g "$resource_group_name" -n "storage_account" --template-file "$storage_template_file" --verbose -o tsv --query "properties.outputs.storage_account_name.value" --parameters \
  location="$location" storage_account_name_infix="$name_infix" storage_account_sku="$storage_account_sku" \
  storage_account_tier="$storage_account_tier" storage_access_tier="$storage_access_tier" \
  vnet_name="$vnet_name" subnet_name_public="$public_subnet_name" subnet_name_private="$private_subnet_name" \
  external_ips_allowed="$external_ips_allowed")"

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
az storage container create --account-name "$storage_account_name" --account-key "$storage_acct_key" -n "$storage_container_name_deploy" --verbose

echo -e "\n"

echo "Upload post-deploy VM shell script"
az storage blob upload --account-name "$storage_account_name" --account-key "$storage_acct_key" -c "$storage_container_name_deploy" -n "$vm_script_file_name" -f "$vm_script_file_path" --verbose

echo -e "\n"

echo "Get storage URL for the VM shell script so VMs can access/run it."
# INLINE VARIABLE INITIALIZATION
vm_script_url="$storage_base_url""/""$storage_container_name_deploy""/""$vm_script_file_name"
echo $vm_script_url

echo -e "\n"

echo "Create User Assigned Managed Identity"
# INLINE VARIABLE INITIALIZATION
mi_principal_id="$(az group deployment create -g "$resource_group_name" -n "mi_name" --template-file "$mi_template_file" --verbose -o tsv --query "properties.outputs.principal_id.value" --parameters tenant_id="$aad_tenant_id" location="$location" mi_name="$mi_name")"
echo "Sleep to wait for MI to finish provisioning..."
sleep 120s
# INLINE VARIABLE INITIALIZATION
mi_client_id="$(az ad sp show --id $mi_principal_id -o tsv --query "appId")"
echo "Managed Identity Principal ID: ""$mi_principal_id"
echo "Managed Identity Client ID: ""$mi_client_id"

echo -e "\n"

echo "Assign Managed Identity rights to read/write data to storage account"
# az role assignment create --scope "$msi_scope_storage" --assignee-object-id "$mi_principal_id" --role "$msi_role_name_storage_acct_contrib"
az group deployment create -g "$resource_group_name" -n "role-assignment-storage" --template-file "$msi_role_template_file" --verbose --parameters \
  role_definition_id="$msi_role_id_storage_acct_contrib" principal_id="$mi_principal_id"

echo -e "\n"

echo "Create Load Balancer"
az group deployment create -g "$resource_group_name" -n "$lb_name" --template-file "$lb_template_file" --verbose --parameters \
  location="$location" vnet_name="$vnet_name" subnet_name="$lb_subnet_name" lb_name="$lb_name" lb_back_end_pool_name="$lb_back_end_pool_name"

echo -e "\n"

echo "Create Gate VMs in public subnet with system-assigned identity"
for ((zone=$azmin;zone<=$azmax;zone++))
do
  echo "Processing Availability Zone ""$zone"

  for ((vm=1;vm<=gate_vm_count_per_avl_zone;vm++))
  do
    vm_name="$name_infix""-pub-gt-z""$zone""-vm""$vm"
    nic_name="$vm_name""-nic"
    public_ip_name="$vm_name""-pip"

    echo "Create VM ""$vm_name"" NIC ""$nic_name"
    az group deployment create -g "$resource_group_name" -n "$nic_name" --template-file "$nic_public_template_file" --verbose --parameters \
      location="$location" nic_name="$nic_name" vnet_name="$vnet_name" subnet_name="$public_subnet_name" \
      enable_accelerated_networking="$gate_vm_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method" \
      public_ip_name="$public_ip_name" public_ip_type="$public_ip_type" public_ip_sku="$public_ip_sku" \
      lb_name="$lb_name" lb_back_end_pool_name="$lb_back_end_pool_name"

    echo "Create VM ""$vm_name"
    az group deployment create -g "$resource_group_name" -n "$vm_name" --template-file "$vm_sai_template_file" --verbose --parameters \
      location="$location" zone="$zone" nic_name="$nic_name" \
      os_publisher="$vm_os_publisher" os_offer="$vm_os_offer" os_sku="$vm_os_sku" \
      vm_name="$vm_name" vm_size="$gate_vm_size" \
      admin_username="$vm_admin_username" admin_public_key="$vm_admin_public_key" \
      data_disk_1_size_in_gb="$gate_vm_disk1_size" data_disk_2_size_in_gb="$gate_vm_disk2_size" \
      script_url="$vm_script_url" script_file_name="$vm_script_file_name" \
      storage_account_name="$storage_account_name" storage_account_key="$storage_acct_key" storage_account_diag_name="$storage_account_diag_name"

    if [ "$gate_vm_autoshutdown" = true ]
    then
      echo "Configure VM Auto-Shutdown for ""$vm_name"
      schedule_name="shutdown-computevm-""$vm_name"
      az group deployment create -g "$resource_group_name" -n "$schedule_name" --template-file "$autoshutdown_template_file" --verbose --no-wait --parameters \
        location="$location" vm_name="$vm_name" shutdown_timezone="$autoshutdown_timezone" shutdown_time="$autoshutdown_time" notification_state="$autoshutdown_notification_state" \
        notification_web_hook_url="$autoshutdown_notification_webhook_url" notification_email="$autoshutdown_notification_email" \
        notification_minutes_before="$autoshutdown_notification_minutes_before" notification_locale="$autoshutdown_notification_locale"
    fi

    echo "Add private FQDN to app GW back end pool list"
    vm_internal_dns_suffix="$(az vm nic show -g "$resource_group_name" --vm-name "$vm_name" --nic "$nic_name" -o tsv --query=dnsSettings.internalDomainNameSuffix)"
    vm_internal_fqdn="$vm_name"".""$vm_internal_dns_suffix"
    echo "$vm_internal_fqdn"
    gate_vm_fqdns+="$vm_internal_fqdn"" "

    echo "Get VM MSI principal ID and display name"
    vm_msi_principal_id="$(az vm identity show -g $resource_group_name -n $vm_name -o tsv --query "principalId")"
    # vm_msi_display_name="$(az ad sp show --id $vm_msi_principal_id -o tsv --query "displayName")"

    echo "Assign VM MSI principal rights to read/write data to storage account"
    az role assignment create --scope "$msi_scope_storage" --assignee-object-id "$vm_msi_principal_id" --role "$msi_role_name_storage_blob_contrib" --verbose
  done
done

echo -e "\n"

echo "Create Server VMs in private subnet with user-assigned identity"
for ((zone=$azmin;zone<=$azmax;zone++))
do
  echo "Processing Availability Zone ""$zone"

  for ((vm=1;vm<=server_vm_count_per_avl_zone;vm++))
  do
    vm_name="$name_infix""-pvt-sv-z""$zone""-vm""$vm"
    nic_name="$vm_name""-nic"

    echo "Create VM ""$vm_name"" NIC ""$nic_name"
    az group deployment create -g "$resource_group_name" -n "$nic_name" --template-file "$nic_private_template_file" --verbose --parameters \
      location="$location" nic_name="$nic_name" vnet_name="$vnet_name" subnet_name="$private_subnet_name" \
      enable_accelerated_networking="$server_vm_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method"

    echo "Create VM ""$vm_name"
    az group deployment create -g "$resource_group_name" -n "$vm_name" --template-file "$vm_uai_template_file" --verbose --parameters \
      location="$location" zone="$zone" nic_name="$nic_name" \
      os_publisher="$vm_os_publisher" os_offer="$vm_os_offer" os_sku="$vm_os_sku" \
      vm_name="$vm_name" vm_size="$server_vm_size" \
      admin_username="$vm_admin_username" admin_public_key="$vm_admin_public_key" \
      data_disk_1_size_in_gb="$server_vm_disk1_size" data_disk_2_size_in_gb="$server_vm_disk2_size" \
      mi_name="$mi_name" \
      script_url="$vm_script_url" script_file_name="$vm_script_file_name" \
      storage_account_name="$storage_account_name" storage_account_key="$storage_acct_key" storage_account_diag_name="$storage_account_diag_name"

    if [ "$server_vm_autoshutdown" = true ]
    then
      echo "Configure VM Auto-Shutdown for ""$vm_name"
      schedule_name="shutdown-computevm-""$vm_name"
      az group deployment create -g "$resource_group_name" -n "$schedule_name" --template-file "$autoshutdown_template_file" --verbose --no-wait --parameters \
        location="$location" vm_name="$vm_name" shutdown_timezone="$autoshutdown_timezone" shutdown_time="$autoshutdown_time" notification_state="$autoshutdown_notification_state" \
        notification_web_hook_url="$autoshutdown_notification_webhook_url" notification_email="$autoshutdown_notification_email" \
        notification_minutes_before="$autoshutdown_notification_minutes_before" notification_locale="$autoshutdown_notification_locale"
    fi
  done
done

echo -e "\n"

echo "Create Data VMs in private subnet with system-assigned identity"
for ((zone=$azmin;zone<=$azmax;zone++))
do
  echo "Processing Availability Zone ""$zone"

  for ((vm=1;vm<=data_vm_count_per_avl_zone;vm++))
  do
    vm_name="$name_infix""-pvt-dt-z""$zone""-vm""$vm"
    nic_name="$vm_name""-nic"

    echo "Create VM ""$vm_name"" NIC ""$nic_name"
    az group deployment create -g "$resource_group_name" -n "$nic_name" --template-file "$nic_private_template_file" --verbose --parameters \
      location="$location" nic_name="$nic_name" vnet_name="$vnet_name" subnet_name="$private_subnet_name" \
      enable_accelerated_networking="$data_vm_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method"

    echo "Create VM ""$vm_name"
    az group deployment create -g "$resource_group_name" -n "$vm_name" --template-file "$vm_sai_template_file" --verbose --parameters \
      location="$location" zone="$zone" nic_name="$nic_name" \
      os_publisher="$vm_os_publisher" os_offer="$vm_os_offer" os_sku="$vm_os_sku" \
      vm_name="$vm_name" vm_size="$data_vm_size" \
      admin_username="$vm_admin_username" admin_public_key="$vm_admin_public_key" \
      data_disk_1_size_in_gb="$data_vm_disk1_size" data_disk_2_size_in_gb="$data_vm_disk2_size" \
      script_url="$vm_script_url" script_file_name="$vm_script_file_name" \
      storage_account_name="$storage_account_name" storage_account_key="$storage_acct_key" storage_account_diag_name="$storage_account_diag_name"

    if [ "$data_vm_autoshutdown" = true ]
    then
      echo "Configure VM Auto-Shutdown for ""$vm_name"
      schedule_name="shutdown-computevm-""$vm_name"
      az group deployment create -g "$resource_group_name" -n "$schedule_name" --template-file "$autoshutdown_template_file" --verbose --no-wait --parameters \
        location="$location" vm_name="$vm_name" shutdown_timezone="$autoshutdown_timezone" shutdown_time="$autoshutdown_time" notification_state="$autoshutdown_notification_state" \
        notification_web_hook_url="$autoshutdown_notification_webhook_url" notification_email="$autoshutdown_notification_email" \
        notification_minutes_before="$autoshutdown_notification_minutes_before" notification_locale="$autoshutdown_notification_locale"
    fi

    echo "Get VM MSI principal ID and display name"
    vm_msi_principal_id="$(az vm identity show -g $resource_group_name -n $vm_name -o tsv --query "principalId")"
    # vm_msi_display_name="$(az ad sp show --id $vm_msi_principal_id -o tsv --query "displayName")"

    echo "Assign VM MSI principal rights to read/write data to storage account"
    az role assignment create --scope "$msi_scope_storage" --assignee-object-id "$vm_msi_principal_id" --role "$msi_role_name_storage_blob_contrib" --verbose
  done
done

echo -e "\n"

echo "Create Search VMs in private subnet with system-assigned identity"
for ((zone=$azmin;zone<=$azmax;zone++))
do
  echo "Processing Availability Zone ""$zone"

  for ((vm=1;vm<=search_vm_count_per_avl_zone;vm++))
  do
    vm_name="$name_infix""-pvt-sr-z""$zone""-vm""$vm"
    nic_name="$vm_name""-nic"

    echo "Create VM ""$vm_name"" NIC ""$nic_name"
    az group deployment create -g "$resource_group_name" -n "$nic_name" --template-file "$nic_private_template_file" --verbose --parameters \
      location="$location" nic_name="$nic_name" vnet_name="$vnet_name" subnet_name="$private_subnet_name" \
      enable_accelerated_networking="$search_vm_enable_accelerated_networking" private_ip_allocation_method="$private_ip_allocation_method"

    echo "Create VM ""$vm_name"
    az group deployment create -g "$resource_group_name" -n "$vm_name" --template-file "$vm_sai_template_file" --verbose --parameters \
      location="$location" zone="$zone" nic_name="$nic_name" \
      os_publisher="$vm_os_publisher" os_offer="$vm_os_offer" os_sku="$vm_os_sku" \
      vm_name="$vm_name" vm_size="$search_vm_size" \
      admin_username="$vm_admin_username" admin_public_key="$vm_admin_public_key" \
      data_disk_1_size_in_gb="$search_vm_disk1_size" data_disk_2_size_in_gb="$search_vm_disk2_size" \
      script_url="$vm_script_url" script_file_name="$vm_script_file_name" \
      storage_account_name="$storage_account_name" storage_account_key="$storage_acct_key" storage_account_diag_name="$storage_account_diag_name"

    if [ "$search_vm_autoshutdown" = true ]
    then
      echo "Configure VM Auto-Shutdown for ""$vm_name"
      schedule_name="shutdown-computevm-""$vm_name"
      az group deployment create -g "$resource_group_name" -n "$schedule_name" --template-file "$autoshutdown_template_file" --verbose --no-wait --parameters \
        location="$location" vm_name="$vm_name" shutdown_timezone="$autoshutdown_timezone" shutdown_time="$autoshutdown_time" notification_state="$autoshutdown_notification_state" \
        notification_web_hook_url="$autoshutdown_notification_webhook_url" notification_email="$autoshutdown_notification_email" \
        notification_minutes_before="$autoshutdown_notification_minutes_before" notification_locale="$autoshutdown_notification_locale"
    fi

    echo "Get VM MSI principal ID and display name"
    vm_msi_principal_id="$(az vm identity show -g $resource_group_name -n $vm_name -o tsv --query "principalId")"
    # vm_msi_display_name="$(az ad sp show --id $vm_msi_principal_id -o tsv --query "displayName")"

    echo "Assign VM MSI principal rights to read/write data to storage account"
    az role assignment create --scope "$msi_scope_storage" --assignee-object-id "$vm_msi_principal_id" --role "$msi_role_name_storage_blob_contrib" --verbose
  done
done


echo -e "\n"

echo "Create App GW"
az group deployment create -g "$resource_group_name" -n "$appgw_name" --template-file "$appgw_template_file" --verbose --parameters \
  location="$location" vnet_name="$vnet_name" subnet_name="$appgw_subnet_name" public_ip_name="$appgw_public_ip_name" appgw_name="$appgw_name" \
  appgw_sku_name="$appgw_sku_name" appgw_sku_tier="$appgw_sku_tier" \
  appgw_enable_http2="$appgw_enable_http2" appgw_autoscale_instances_min="$appgw_autoscale_instances_min" appgw_autoscale_instances_max="$appgw_autoscale_instances_max" \
  appgw_back_end_pool_name="$appgw_back_end_pool_name"

echo "Add back end instances"
be_pool_items=("$gate_vm_fqdns")
az network application-gateway address-pool update -g "$resource_group_name" --gateway-name "$appgw_name" -n "$appgw_back_end_pool_name" --servers $be_pool_items --verbose --no-wait

echo -e "\n"

echo "Completing: ""`date`"
echo "All deployments initiated. Some async (no-wait) deployments may still be executing."
az group deployment list -g "$resource_group_name" -o table --query '[].{Name:name, State:properties.provisioningState, Duration:properties.duration}'
