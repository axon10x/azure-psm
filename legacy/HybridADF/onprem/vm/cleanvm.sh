#!/bin/bash

resource_group_name="aza-o"
vm_prefix="aza-o-host"

az vm delete -g "$resource_group_name" -n "$vm_prefix-1" --yes

az disk delete -g "$resource_group_name" -n "$vm_prefix-1-os" --yes
az disk delete -g "$resource_group_name" -n "$vm_prefix-1-data-1" --yes

az network nic delete -g "$resource_group_name" -n "$vm_prefix-1-nic"
az network public-ip delete -g "$resource_group_name" -n "$vm_prefix-1-pip"

az vm availability-set delete -g "$resource_group_name" -n "$vm_prefix-avset"