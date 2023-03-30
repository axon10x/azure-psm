#!/bin/bash

# Get all storage accounts in subscription, then set soft delete on each.

days_to_retain=7
accts="$(az storage account list -o tsv --query '[].name')"

# Set the policy on each storage account: enable soft delete and set retention time
for acct in $accts
do
    echo "$acct"
    az storage blob service-properties delete-policy update --days-retained "$days_to_retain" --account-name "$acct" --enable true
done

# Optionally iterate through and just verify for each storage account
for acct in $accts
do
    echo "$acct"
    az storage blob service-properties delete-policy show --account-name "$acct"
done
