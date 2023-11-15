function Get-DiagnosticsSettingsForSub()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = ""
  )
  Write-Debug -Debug:$true -Message "Get-DiagnosticsSettingsForSub $ResourceName"

  [System.Collections.ArrayList]$result = @()

  if ($LogAnalyticsWorkspaceId)
  {
    $query = "(value)[?(workspaceId=='" + $LogAnalyticsWorkspaceId + "')].{name:name, id:id}"
  }
  else
  {
    $query = "(value)[].{name:name, id:id}"
  }

  $settings = "$(az monitor diagnostic-settings subscription list --subscription $SubscriptionId --query "$query" 2>nul)" | ConvertFrom-Json

  if ($settings) { $result.Add($settings) | Out-Null }

  return $result
}

function Remove-DiagnosticsSettingsForSub()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = ""
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSettingsForSub $SubscriptionId"

  $settings = Get-DiagnosticsSettingsForSub -SubscriptionId $SubscriptionId -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId

  foreach ($setting in $settings)
  {
    $dgid = "/" + $setting.id
    az monitor diagnostic-settings subscription delete --ids $dgid --yes
  }
}

function Get-DiagnosticsSettingsForResource()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = "",
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName
  )
  Write-Debug -Debug:$true -Message "Get-DiagnosticsSettingsForResource $ResourceName"

  [System.Collections.ArrayList]$result = @()

  if ($LogAnalyticsWorkspaceId)
  {
    $query = "[?(workspaceId=='" + $LogAnalyticsWorkspaceId + "')].{name:name, id:id}"
  }
  else
  {
    $query = "[].{name:name, id:id}"
  }

  # Main resource diagnostic settings
  $settings = "$(az monitor diagnostic-settings list --subscription $SubscriptionId --resource $ResourceId --query "$query" 2>nul)" | ConvertFrom-Json

  if ($settings) { $result.Add($settings) | Out-Null }

  if ($ResourceId.EndsWith("Microsoft.Storage/storageAccounts/" + $ResourceName))
  {
    $rid = $ResourceId + "/blobServices/default"
    $settings = "$(az monitor diagnostic-settings list --subscription $SubscriptionId --resource $rid --query "$query" 2>nul)" | ConvertFrom-Json
    if ($settings) { $result.Add($settings) | Out-Null }

    $rid = $ResourceId + "/fileServices/default"
    $settings = "$(az monitor diagnostic-settings list --subscription $SubscriptionId --resource $rid --query "$query" 2>nul)" | ConvertFrom-Json
    if ($settings) { $result.Add($settings) | Out-Null }

    $rid = $ResourceId + "/queueServices/default"
    $settings = "$(az monitor diagnostic-settings list --subscription $SubscriptionId --resource $rid --query "$query" 2>nul)" | ConvertFrom-Json
    if ($settings) { $result.Add($settings) | Out-Null }

    $rid = $ResourceId + "/tableServices/default"
    $settings = "$(az monitor diagnostic-settings list --subscription $SubscriptionId --resource $rid --query "$query" 2>nul)" | ConvertFrom-Json
    if ($settings) { $result.Add($settings) | Out-Null }
  }

  return $result
}

function Remove-DiagnosticsSettingsForAllResources()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = ""
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSettingsForAllResources on Log Analytics $LogAnalyticsWorkspaceId"

  $resources = "$(az resource list --subscription $SubscriptionId --query '[].{name:name, id:id}')" | ConvertFrom-Json

  foreach ($resource in $resources)
  {
    Remove-DiagnosticsSettingsForResource -SubscriptionId $SubscriptionId -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -ResourceId $resource.id -ResourceName $resource.name
  }
}

function Remove-DiagnosticsSettingsForResource()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = "",
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSettingsForResource $ResourceName"

  $settings = Get-DiagnosticsSettingsForResource -SubscriptionId $SubscriptionId -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -ResourceId $ResourceId -ResourceName $ResourceName

  if ($settings.Count -gt 0)
  {
    foreach ($setting in $settings)
    {
      Remove-DiagnosticsSetting `
        -SubscriptionId $SubscriptionId `
        -DiagnosticsSettingName $setting.name `
        -ResourceId $ResourceId `
        -ResourceName $ResourceName
    }
  }
}

function Remove-DiagnosticsSetting()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $DiagnosticsSettingName,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSetting $DiagnosticsSettingName from $ResourceName"

  az monitor diagnostic-settings delete --subscription $SubscriptionId --name $DiagnosticsSettingName --resource $ResourceId
}

function New-DiagnosticsSetting()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $DiagnosticsSettingName,
    [Parameter(Mandatory=$true)]
    [string]
    $LogAnalyticsWorkspaceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $SendLogs,
    [Parameter(Mandatory=$true)]
    [string]
    $SendMetrics
  )
  Write-Debug -Debug:$true -Message "New-DiagnosticsSetting $DiagnosticsSettingName on $ResourceId"

  az deployment group create `
    -n "$DiagnosticsSettingName" `
    -g "$ResourceGroupName" `
    --template-file "./template/diagnostic-settings.json" `
    --parameters `
    resourceId="$ResourceId" `
    diagnosticsSettingName="$DiagnosticsSettingName" `
    logAnalyticsWorkspaceResourceId="$LogAnalyticsWorkspaceId" `
    sendLogs=$SendLogs `
    sendMetrics=$SendMetrics
}