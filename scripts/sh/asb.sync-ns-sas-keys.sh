#!/bin/bash

# This script synchronizes Azure Service Bus namespace keys from a source to a destination namespace.
# Why use this? In case you have a scenario (e.g. active/active or active/passive) and you cannot refer to each namespace by individual connection string or key.
# Example: JMS client failover-enabled connection string does not allow for specification of individual keys for each targeted namespace; only one key can be specified.

subscriptionId="$(az account show -o tsv --query 'id')"
resourceGroupName="tm"
asbNamespaceNameSource="pz-asb-eus2"
asbNamespaceNameDestination="pz-asb-cus"
sasPolicyName="RootManageSharedAccessKey" # Policy must exist on both namespaces. Substitute name of policy whose keys to sync.

# Source namespace RootManageSharedAccessKey
primaryKey="$(az servicebus namespace authorization-rule keys list --subscription "$subscriptionId" -g "$resourceGroupName" --namespace-name "$asbNamespaceNameSource" -n "$sasPolicyName" -o tsv --query 'primaryKey')"
secondaryKey="$(az servicebus namespace authorization-rule keys list --subscription "$subscriptionId" -g "$resourceGroupName" --namespace-name "$asbNamespaceNameSource" -n "$sasPolicyName" -o tsv --query 'secondaryKey')"

# Set to destination namespace
az servicebus namespace authorization-rule keys renew --subscription "$subscriptionId" --verbose \
	-g "$resourceGroupName" --namespace-name "$asbNamespaceNameDestination" -n "$sasPolicyName" \
	--key PrimaryKey --key-value "$primaryKey"

az servicebus namespace authorization-rule keys renew --subscription "$subscriptionId" --verbose \
	-g "$resourceGroupName" --namespace-name "$asbNamespaceNameDestination" -n "$sasPolicyName" \
	--key SecondaryKey --key-value "$secondaryKey"
