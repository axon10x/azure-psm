param
(
  [string]$resourceGroupName,
  [string]$functionAppName,
  [string]$publicNetworkAccess # Enabled or Disabled
)

az functionapp config set -g $resourceGroupName -n $functionAppName --generic-configurations "{'publicNetworkAccess':'$publicNetworkAccess'}"
