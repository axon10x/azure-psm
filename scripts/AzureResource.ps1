function Get-ChildResourceId()
{
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ParentResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $ChildResourceTypeName,
    [Parameter(Mandatory = $true)]
    [string]
    $ChildResourceName
  )

  Write-Debug -Debug:$debug -Message ("Get-ChildResourceId: ParentResourceId: " + "$ParentResourceId" + ", ChildResourceTypeName: " + "$ChildResourceTypeName" + ", ChildResourceName: " + "$ChildResourceName")

  $result = $ParentResourceId + "/" + $ChildResourceTypeName + "/" + $ChildResourceName

  return $result
}

function Get-ResourceId()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceProviderName,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceTypeName,
    [Parameter(Mandatory = $false)]
    [string]
    $ResourceSubTypeName = "",
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceName,
    [Parameter(Mandatory = $false)]
    [string]
    $ChildResourceTypeName = "",
    [Parameter(Mandatory = $false)]
    [string]
    $ChildResourceName = ""
  )

  Write-Debug -Debug:$debug -Message ("Get-ResourceId: SubscriptionId: " + "$SubscriptionId" + ", ResourceGroupName: " + "$ResourceGroupName" + ", ResourceProviderName: " + "$ResourceProviderName" + ", ResourceTypeName: " + "$ResourceTypeName" + ", ResourceName: " + "$ResourceName" + ", ChildResourceTypeName: " + "$ChildResourceTypeName" + ", ChildResourceName: " + "$ChildResourceName")

  $result = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/" + $ResourceProviderName + "/" + $ResourceTypeName + "/"
  
  if ($ResourceSubTypeName)
  {
    $result += $ResourceSubTypeName + "/"
  }

  $result += $ResourceName

  if ($ChildResourceTypeName -and $ChildResourceName)
  {
    $result += "/" + $ChildResourceTypeName + "/" + $ChildResourceName
  }

  return $result
}

function Get-ResourceName()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigConstants,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMain,
    [Parameter(Mandatory = $false)]
    [string]
    $Prefix = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Sequence = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Suffix = "",
    [Parameter(Mandatory = $false)]
    [bool]
    $IncludeDelimiter = $true
  )

  Write-Debug -Debug:$debug -Message ("Get-ResourceName: Prefix: " + "$Prefix" + ", Sequence: " + "$Sequence" + ", Suffix: " + "$Suffix" + ", IncludeDelimiter: " + "$IncludeDelimiter")

  if ($IncludeDelimiter)
  {
    $delimiter = "-"
  }
  else
  {
    $delimiter = ""
  }

  $result = ""

  if ($ConfigConstants.NamePrefix) { $result = $ConfigConstants.NamePrefix }
  if ($ConfigConstants.NameInfix) { $result += $delimiter + $ConfigConstants.NameInfix }

  if ($ConfigMain.LocationShort) { $result += $delimiter + $ConfigMain.LocationShort}

  if ($Prefix) { $result = $Prefix + $delimiter + $result }
  if ($Sequence) { $result += $delimiter + $Sequence }
  if ($Suffix) { $result += $delimiter + $Suffix }

  return $result
}

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