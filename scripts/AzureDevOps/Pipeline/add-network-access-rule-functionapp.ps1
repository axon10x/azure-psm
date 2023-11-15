param
(
  [string]$resourceGroupName,
  [string]$functionAppName,
  [int]$priority = 200,
  [string]$ruleName
)

$action = "Allow"

$ipAddress = Invoke-RestMethod https://ipinfo.io/json | Select-Object -exp ip
Write-Debug -Debug:$true -Message $ipAddress

az functionapp config access-restriction add -g $resourceGroupName -n $functionAppName --priority $priority --rule-name $ruleName --action $action --ip-address $ipAddress
