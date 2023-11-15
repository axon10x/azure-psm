param
(
  [string]$resourceGroupName,
  [string]$webAppName,
  [string]$publicNetworkAccess # Enabled or Disabled
)

az webapp config set -g $resourceGroupName -n $webAppName --generic-configurations "{'publicNetworkAccess':'$publicNetworkAccess'}"
