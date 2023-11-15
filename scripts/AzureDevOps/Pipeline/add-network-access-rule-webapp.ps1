param
(
  [string]$resourceGroupName,
  [string]$webAppName,
  [string]$ruleName,
  [int]$priority = 200
)

$action = "Allow"

$ipAddress = Invoke-RestMethod https://ipinfo.io/json | Select-Object -exp ip
Write-Debug -Debug:$true -Message $ipAddress

az webapp config access-restriction add -g $resourceGroupName -n $webAppName --priority $priority --rule-name $ruleName --action $action --ip-address $ipAddress
