param
(
  [string]$resourceGroupName,
  [string]$functionAppName,
  [string]$ruleName
)

az functionapp config access-restriction remove -g $resourceGroupName -n $functionAppName --rule-name $ruleName
