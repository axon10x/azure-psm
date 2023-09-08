#!/bin/bash

# Login first
# az login

echo "This script assumes you are at a terminal in the onprem folder, i.e. co-located with this script"
echo "You should have replaced ###PROVIDE### tokens with meaningful values for your environment before running this!"

# ##################################################

deployment_tech="cli" # template or cli for some of the infra stuff

prefix="zbr"   # This is just a naming prefix used to create other variable values, like resource group names and such

onprem_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

onprem_region="eastus"
onprem_resource_group_name="$prefix-o"

onprem_template_path_nsg="$onprem_dir/nsg.template.json"
onprem_nsg_name="$prefix-o-nsg-1"
onprem_nsg_rule_name="AllowExternal"
onprem_nsg_rule_priority=100
onprem_external_ips_allowed="###PROVIDE###"
onprem_destination_ips_allowed="VirtualNetwork"

onprem_template_path_vnet="$onprem_dir/vnet.template.json"
onprem_vnet_name="$prefix-o-vnet-1"
onprem_vnet_address_space="10.1.0.0/16"

onprem_template_path_subnet="$onprem_dir/subnet.template.json"
onprem_subnet_name="o-subnet-1"
onprem_subnet_address_space="10.1.1.0/24"

onprem_template_path_vm_sql="$onprem_dir/vm-sql.template.json"

onprem_db_ref_avset_name="$prefix-o-db-ref-avset"
onprem_db_ref_vm_name="$prefix-o-db-ref-1"
onprem_db_ref_vm_size="Standard_DS3_v2"
onprem_db_ref_vm_publisher="MicrosoftSQLServer"
onprem_db_ref_vm_offer="SQL2017-WS2016"
onprem_db_ref_vm_sku="SQLDEV"
onprem_db_ref_vm_admin_username="vmadmin"
onprem_db_ref_vm_admin_password="###PROVIDE###"
onprem_db_ref_vm_time_zone="Eastern Standard Time"
onprem_db_ref_vm_auto_shutdown_time="1830"

onprem_db_tx_avset_name="$prefix-o-db-tx-avset"
onprem_db_tx_vm_name="$prefix-o-db-tx-1"
onprem_db_tx_vm_size="Standard_DS3_v2"
onprem_db_tx_vm_publisher="MicrosoftSQLServer"
onprem_db_tx_vm_offer="SQL2017-WS2016"
onprem_db_tx_vm_sku="SQLDEV"
onprem_db_tx_vm_admin_username="vmadmin"
onprem_db_tx_vm_admin_password="###PROVIDE###"
onprem_db_tx_vm_time_zone="Eastern Standard Time"
onprem_db_tx_vm_auto_shutdown_time="1830"

onprem_template_path_vm_host="$onprem_dir/vm-host.template.json"
onprem_host_avset_name="$prefix-o-host-avset"
onprem_host_vm_size="Standard_DS3_v2"
onprem_host_vm_publisher="MicrosoftWindowsServer"
onprem_host_vm_offer="WindowsServer"
onprem_host_vm_sku="2019-Datacenter"
onprem_host_vm_admin_username="vmadmin"
onprem_host_vm_admin_password="###PROVIDE###"
onprem_host_vm_time_zone="Eastern Standard Time"
onprem_host_vm_auto_shutdown_time="1830"

onprem_host_vm_name_1="$prefix-o-host-1"
onprem_host_vm_name_2="$prefix-o-host-2"

# ##################################################

# ##################################################
echo "Create resource group"
az group create -l $onprem_region -n $onprem_resource_group_name --verbose
# ##################################################

# ##################################################
echo "Create network security group (NSG) and inbound NSG rule"

if [ $deployment_tech == "cli" ]
then
    az network nsg create -l $onprem_region -g $onprem_resource_group_name -n $onprem_nsg_name

    az network nsg rule create -g $onprem_resource_group_name --nsg-name $onprem_nsg_name -n $onprem_nsg_rule_name \
        --priority $onprem_nsg_rule_priority --direction Inbound --protocol "*" --access Allow \
        --source-address-prefixes $onprem_external_ips_allowed --source-port-ranges "*" \
        --destination-address-prefixes $onprem_destination_ips_allowed --destination-port-ranges "*"
elif [ $deployment_tech == "template" ]
then
    az group deployment create -g $onprem_resource_group_name --template-file $onprem_template_path_nsg --verbose \
        --parameters location=$onprem_region nsg_name=$onprem_nsg_name external_ips_allowed=$onprem_external_ips_allowed destination_address_space=$onprem_destination_ips_allowed
fi

# ##################################################

# ##################################################
echo "Create virtual network (VNet), subnet, and associate subnet with NSG"

if [ $deployment_tech == "cli" ]
then
    az network vnet create -l $onprem_region -g $onprem_resource_group_name -n $onprem_vnet_name --address-prefixes $onprem_vnet_address_space

    az network vnet subnet create -g $onprem_resource_group_name -n $onprem_subnet_name --vnet-name $onprem_vnet_name \
        --address-prefixes $onprem_subnet_address_space --network-security-group $onprem_nsg_name
elif [ $deployment_tech == "template" ]
then
    az group deployment create -g $onprem_resource_group_name --template-file $onprem_template_path_vnet --verbose \
        --parameters location=$onprem_region vnet_name=$onprem_vnet_name vnet_address_space=$onprem_vnet_address_space

    az group deployment create -g $onprem_resource_group_name --template-file $onprem_template_path_subnet --verbose \
        --parameters location=$onprem_region vnet_name=$onprem_vnet_name nsg_name=$onprem_nsg_name subnet_name=$onprem_subnet_name subnet_address_space=$onprem_subnet_address_space
fi

# ##################################################

# ##################################################
# On-prem (stand-in) VMs
# Template only due to dependencies and complexity

# SQL Ref
echo "Create on-prem ref data source"
az group deployment create -g "$onprem_resource_group_name" --template-file "$onprem_template_path_vm_sql" --verbose --parameters \
    location="$onprem_region" resource_group_name_vm="$onprem_resource_group_name" availability_set_name="$onprem_db_ref_avset_name" \
    virtual_machine_name="$onprem_db_ref_vm_name" virtual_machine_size="$onprem_db_ref_vm_size" \
    publisher="$onprem_db_ref_vm_publisher" offer="$onprem_db_ref_vm_offer" sku="$onprem_db_ref_vm_sku" \
    admin_username="$onprem_db_ref_vm_admin_username" admin_password="$onprem_db_ref_vm_admin_password" \
    virtual_machine_time_zone="$onprem_db_ref_vm_time_zone" virtual_machine_auto_shutdown_time="$onprem_db_ref_vm_auto_shutdown_time" \
    resource_group_name_network="$onprem_resource_group_name" vnet_name="$onprem_vnet_name" subnet_name="$onprem_subnet_name"

# SQL Tx
echo "Create on-prem tx data source"
az group deployment create -g "$onprem_resource_group_name" --template-file "$onprem_template_path_vm_sql" --verbose --parameters \
    location="$onprem_region" resource_group_name_vm="$onprem_resource_group_name" availability_set_name="$onprem_db_tx_avset_name" \
    virtual_machine_name="$onprem_db_tx_vm_name" virtual_machine_size="$onprem_db_tx_vm_size" \
    publisher="$onprem_db_tx_vm_publisher" offer="$onprem_db_tx_vm_offer" sku="$onprem_db_tx_vm_sku" \
    admin_username="$onprem_db_tx_vm_admin_username" admin_password="$onprem_db_tx_vm_admin_password" \
    virtual_machine_time_zone="$onprem_db_tx_vm_time_zone" virtual_machine_auto_shutdown_time="$onprem_db_tx_vm_auto_shutdown_time" \
    resource_group_name_network="$onprem_resource_group_name" vnet_name="$onprem_vnet_name" subnet_name="$onprem_subnet_name"

# SHIR Host 1
echo "Create on-prem SHIR host 1"
az group deployment create -g "$onprem_resource_group_name" --template-file "$onprem_template_path_vm_host" --verbose --parameters \
    location="$onprem_region" resource_group_name_vm="$onprem_resource_group_name" availability_set_name="$onprem_host_avset_name" \
    virtual_machine_name="$onprem_host_vm_name_1" virtual_machine_size="$onprem_host_vm_size" \
    publisher="$onprem_host_vm_publisher" offer="$onprem_host_vm_offer" sku="$onprem_host_vm_sku" \
    admin_username="$onprem_host_vm_admin_username" admin_password="$onprem_host_vm_admin_password" \
    virtual_machine_time_zone="$onprem_host_vm_time_zone" virtual_machine_auto_shutdown_time="$onprem_host_vm_auto_shutdown_time" \
    resource_group_name_network="$onprem_resource_group_name" vnet_name="$onprem_vnet_name" subnet_name="$onprem_subnet_name"

echo "Create on-prem SHIR host 2"
az group deployment create -g "$onprem_resource_group_name" --template-file "$onprem_template_path_vm_host" --verbose --parameters \
    location="$onprem_region" resource_group_name_vm="$onprem_resource_group_name" availability_set_name="$onprem_host_avset_name" \
    virtual_machine_name="$onprem_host_vm_name_2" virtual_machine_size="$onprem_host_vm_size" \
    publisher="$onprem_host_vm_publisher" offer="$onprem_host_vm_offer" sku="$onprem_host_vm_sku" \
    admin_username="$onprem_host_vm_admin_username" admin_password="$onprem_host_vm_admin_password" \
    virtual_machine_time_zone="$onprem_host_vm_time_zone" virtual_machine_auto_shutdown_time="$onprem_host_vm_auto_shutdown_time" \
    resource_group_name_network="$onprem_resource_group_name" vnet_name="$onprem_vnet_name" subnet_name="$onprem_subnet_name"
# ##################################################
