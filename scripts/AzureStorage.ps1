function Deploy-StorageAccount()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $SkuName,
    [Parameter(Mandatory = $false)]
    [string]
    $SkuTier = "Standard",
    [Parameter(Mandatory = $false)]
    [bool]
    $HierarchicalEnabled = $false,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedSubnetResourceIdsCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedIpAddressRangesCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Storage Account $StorageAccountName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$StorageAccountName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    storageAccountName="$StorageAccountName" `
    skuName=$SkuName `
    skuTier=$SkuTier `
    hierarchicalEnabled="$HierarchicalEnabled" `
    publicNetworkAccess="$PublicNetworkAccess" `
    allowedSubnetResourceIds="$AllowedSubnetResourceIdsCsv" `
    allowedIpAddressRanges="$AllowedIpAddressRangesCsv" `
    defaultAccessAction=$DefaultAction `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-StorageDiagnosticsSetting()
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
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $DiagnosticsSettingName,
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceResourceId
  )

  Write-Debug -Debug:$true -Message "Deploy Storage Diagnostics Setting $DiagnosticsSettingName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DiagnosticsSettingName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    resourceId="$ResourceId" `
    diagnosticsSettingName="$DiagnosticsSettingName" `
    logAnalyticsWorkspaceResourceId="$LogAnalyticsWorkspaceResourceId" `
    | ConvertFrom-Json

  return $output
}

function New-StorageObjects()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $ContainerNames,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $QueueNames,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $TableNames
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  Write-Debug -Debug:$debug -Message "Get key for $StorageAccountName"
  $accountKey = "$(az storage account keys list --account-name $StorageAccountName -o tsv --query '[0].value')"

  # Blob
  foreach ($containerName in $ContainerNames)
  {
    Write-Debug -Debug:$debug -Message "Create container $containerName"
    az storage container create --account-name $StorageAccountName --account-key $accountKey -n $containerName
  }

  # Queue
  foreach ($queueName in $QueueNames)
  {
    Write-Debug -Debug:$debug -Message "Create queue $queueName"
    az storage queue create --account-name $StorageAccountName --account-key $accountKey -n $queueName
  }

  # Table
  foreach ($tableName in $TableNames)
  {
    Write-Debug -Debug:$debug -Message "Create table $tableName"
    az storage table create --account-name $StorageAccountName --account-key $accountKey -n $tableName
  }
}

function Remove-ContainersByNamePrefix()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $NamePrefix
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  $query = "[?starts_with(name, '" + $NamePrefix + "')].name"
  $containerNames = $(az storage container list --account-name $StorageAccountName --auth-mode login -o tsv --query $query)

  foreach ($containerName in $containerNames)
  {
    Write-Debug -Debug:$debug -Message "Deleting container $containerName"
    az storage container delete --account-name $StorageAccountName -n $containerName --auth-mode login 
  }
  else
  {
    Write-Debug -Debug:$debug -Message ("No Op on container $containerName")
  }
}

function Remove-ContainersByNamePrefixAndAge()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $NamePrefix,
    [Parameter(Mandatory = $true)]
    [int]
    $DaysOlderThan
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  $query = "[?starts_with(name, '" + $NamePrefix + "')].{Name: name, LastModified: properties.lastModified}"
  $containers = $(az storage container list --account-name $StorageAccountName --auth-mode login --query $query) | ConvertFrom-Json

  $daysBack = -1 * [Math]::Abs($DaysOlderThan) # Just in case someone passes a negative number to begin with
  $compareDate = (Get-Date).AddDays($daysBack)

  foreach ($container in $containers)
  {
    $deleteThis = ($compareDate -gt [DateTime]$container.LastModified)

    if ($deleteThis)
    {
      Write-Debug -Debug:$debug -Message ("Deleting container " + $container.Name)
      az storage container delete --account-name $StorageAccountName -n $container.Name --auth-mode login 
    }
    else
    {
      Write-Debug -Debug:$debug -Message ("No Op on container " + $container.Name)
    }
  }
}

function Remove-StorageObjects()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $ContainerNames,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $QueueNames,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $TableNames
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  Write-Debug -Debug:$debug -Message "Get key for $StorageAccountName"
  $accountKey = "$(az storage account keys list --account-name $StorageAccountName -o tsv --query '[0].value')"

  # Blob
  foreach ($containerName in $ContainerNames)
  {
    Write-Debug -Debug:$debug -Message "Delete container $containerName"
    az storage container delete --account-name $StorageAccountName --account-key $accountKey -n $containerName
  }

  # Queue
  foreach ($queueName in $QueueNames)
  {
    Write-Debug -Debug:$debug -Message "Delete queue $queueName"
    az storage queue delete --account-name $StorageAccountName --account-key $accountKey -n $queueName
  }

  # Table
  foreach ($tableName in $TableNames)
  {
    Write-Debug -Debug:$debug -Message "Delete table $tableName"
    az storage table delete --account-name $StorageAccountName --account-key $accountKey -n $tableName
  }
}

function Remove-TablesByNamePrefix()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $NamePrefix
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  $query = "[?starts_with(name, '" + $NamePrefix + "')].name"
  $tableNames = $(az storage table list --account-name $StorageAccountName --auth-mode login -o tsv --query $query)

  foreach ($tableName in $tableNames)
  {
    Write-Debug -Debug:$debug -Message "Deleting table $tableName"
    az storage table delete --account-name $StorageAccountName -n $tableName --auth-mode login 
  }
  else
  {
    Write-Debug -Debug:$debug -Message ("No Op on table $tableName")
  }
}

function Remove-TablesByNamePrefixAndAge()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $NamePrefix,
    [Parameter(Mandatory = $true)]
    [int]
    $DaysOlderThan
  )

  Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  $query = "[?starts_with(name, '" + $NamePrefix + "')].name"
  $tableNames = $(az storage table list --account-name $StorageAccountName --auth-mode login -o tsv --query $query)

  $daysBack = -1 * [Math]::Abs($DaysOlderThan) # Just in case someone passes a negative number to begin with
  $compareDate = (Get-Date).AddDays($daysBack)

  foreach ($tableName in $tableNames)
  {
    # Get the date block in the table name
    $d1 = $tableName.Substring(3, 16)

    # Fix the string back to something Powershell DateTime can work with
    $d2 = `
      $d1.Substring(0, 4) + `
      "-" + `
      $d1.Substring(4, 2) + `
      "-" + `
      $d1.Substring(6, 5) + `
      ":" + `
      $d1.Substring(11, 2) + `
      ":" + `
      $d1.Substring(13)

    # Convert to DateTime for comparison
    $d3 = [DateTime]$d2

    $deleteThis = ($compareDate -gt $d3)

    if ($deleteThis)
    {
      Write-Debug -Debug:$debug -Message ("Deleting table $tableName")
      az storage table delete --account-name $StorageAccountName -n $tableName --auth-mode login 
    }
    else
    {
      Write-Debug -Debug:$debug -Message ("No Op on table $tableName")
    }
  }
}

function Set-StorageAccountPublicNetworkAccess()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny" # Allow or Deny
  )
  az storage account update --name $StorageAccountName --default-action $DefaultAction
}
