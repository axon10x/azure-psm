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