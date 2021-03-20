#!/bin/bash

resource_group_name=$1

az group deployment list -g "$resource_group_name" -o table --query '[].{Name:name, State:properties.provisioningState, Duration:properties.duration}'
