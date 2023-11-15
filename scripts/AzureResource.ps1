function Remove-ResourceGroup()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName
  )

  $rgExists = Test-ResourceGroupExists -rgName $ResourceGroupName

  if ($rgExists)
  {
    Write-Debug -Debug:$true -Message "Delete Resource Group locks for $ResourceGroupName"
    $lockIds = "$(az lock list -g $ResourceGroupName -o tsv --query '[].id')" | Where-Object { $_ }
    foreach ($lockId in $lockIds)
    {
      az lock delete --ids "$lockId"
    }

    Write-Debug -Debug:$true -Message "Delete Resource Group $ResourceGroupName"
    az group delete -n $ResourceGroupName --yes
  }
  else
  {
    Write-Debug -Debug:$true -Message "Resource Group $ResourceGroupName not found"
  }
}

function Test-ResourceGroupExists()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName
  )

  $rgExists = [System.Convert]::ToBoolean("$(az group exists -n $ResourceGroupName)")

  return $rgExists
}