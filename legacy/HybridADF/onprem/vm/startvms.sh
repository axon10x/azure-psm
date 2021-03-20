#!/bin/bash

prefix="aza"
onprem_resource_group_name="$prefix-o"
onprem_db_ref_vm_name="$prefix-o-db-ref-1"
onprem_db_tx_vm_name="$prefix-o-db-tx-1"
onprem_host_vm_name_1="$prefix-o-host-1"
onprem_host_vm_name_2="$prefix-o-host-2"

az vm start -g "$onprem_resource_group_name" --no-wait -n "$onprem_db_ref_vm_name"
az vm start -g "$onprem_resource_group_name" --no-wait -n "$onprem_db_tx_vm_name"
az vm start -g "$onprem_resource_group_name" --no-wait -n "$onprem_host_vm_name_1"
az vm start -g "$onprem_resource_group_name" --no-wait -n "$onprem_host_vm_name_2"
