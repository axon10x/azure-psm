#!/bin/bash

subscription_id=""
resource_group=""
workspace_name=""
destination_resource_id=""

az monitor log-analytics workspace data-export create \
	--subscription "$subscription_id" \
	-g "$resource_group" \
	-n "" \
	--workspace-name "$workspace_name" \
	--destination "$destination_resource_id" \
	--enable true \
	--all true \
	--tables true
