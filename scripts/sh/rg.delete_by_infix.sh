#!/bin/bash

subscription_id=""
rg_infix=""

rgs="$(az group list --subscription "$subscription_id" -o tsv --query "[?name.starts_with(@, '$rg_infix')].name")"

for rg in $rgs
do
	az group delete --subscription "$subscription_id" -g "$rg" --yes
done