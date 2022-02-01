#!/bin/bash

resource_group_name=$1

az vm list -g $resource_group_name -o table --query '[].{Name:name, Location:location, Size:hardwareProfile.vmSize}'
