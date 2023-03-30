#!/bin/bash

# Gets Resource Provider Aliases that can be used in a custom policy definition

namespace="Microsoft.DocumentDB"
type="microsoft.DocumentDB"
subscription_id="$(az account show -o tsv --query "id")"

az provider show --namespace "$namespace" --expand "resourceTypes/aliases" --query "resourceTypes[].aliases[].name"

az graph query -q "Resources | where type=~'"$type"' | limit 1 | project aliases" --subscriptions $subscription_id
