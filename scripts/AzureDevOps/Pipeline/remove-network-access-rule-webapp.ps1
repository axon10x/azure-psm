param
(
  [string]$resourceGroupName,
  [string]$webAppName,
  [string]$ruleName
)

az webapp config access-restriction remove -g $resourceGroupName -n $webAppName --rule-name $ruleName
