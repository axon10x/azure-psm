function Set-FunctionKey()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $FunctionAppName,
    [Parameter(Mandatory=$true)]
    [string]
    $FunctionKeyName
  )
  Write-Debug -Debug:$true -Message "Set new function key $FunctionKeyName on app $FunctionAppName and get its value on the output"
  $keyValue = "$(az functionapp keys set --key-name $FunctionKeyName --key-type functionKeys --name $FunctionAppName -g $ResourceGroupName -o tsv --query 'value')"

  return $keyValue
}

function Get-FunctionIdentityPrincipalId()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $FunctionAppName
  )
  Write-Debug -Debug:$true -Message "Get function identity principal id for app $FunctionAppName"
  $principalId = "$(az functionapp identity show --name $FunctionAppName -g $ResourceGroupName -o tsv --query 'principalId')"

  return $principalId
}
