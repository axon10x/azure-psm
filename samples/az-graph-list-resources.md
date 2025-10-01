# CLI command to list all resources of type storage account which have a tag with specified name and value
az graph query -q "Resources | where type =~ 'Microsoft.Storage/storageAccounts' | where tags['foo'] =~ 'bar' | project id"

