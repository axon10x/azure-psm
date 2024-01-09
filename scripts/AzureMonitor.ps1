function Deploy-ActionGroup()
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
    $ActionGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $ActionGroupShortName,
    [Parameter(Mandatory = $false)]
    [string]
    $EmailReceivers = "",
    [Parameter(Mandatory = $false)]
    [string]
    $SmsReceivers = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AzureAppPushReceivers = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Action Group $ActionGroupName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$ActionGroupName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    actionGroupName="$ActionGroupName" `
    actionGroupShortName=acg1="$ActionGroupShortName" `
    emailReceivers="$EmailReceivers" `
    smsReceivers="$SmsReceivers" `
    azureAppPushReceivers="$AzureAppPushReceivers" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-DiagnosticsSetting()
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
    $LogAnalyticsWorkspaceResourceId,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendLogs = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendMetrics = $true
  )

  Write-Debug -Debug:$true -Message "Deploy Diagnostics Setting $DiagnosticsSettingName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DiagnosticsSettingName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    resourceId="$ResourceId" `
    diagnosticsSettingName="$DiagnosticsSettingName" `
    logAnalyticsWorkspaceResourceId="$LogAnalyticsWorkspaceResourceId" `
    sendLogs=$SendLogs `
    sendMetrics=$SendMetrics `
    | ConvertFrom-Json

  return $output
}

function Deploy-LogAnalyticsWorkspace() {
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
    $WorkspaceName,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccessForIngestion = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccessForQuery = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Log Analytics Workspace $WorkspaceName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$WorkspaceName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    workspaceName="$WorkspaceName" `
    publicNetworkAccessForIngestion="$PublicNetworkAccessForIngestion" `
    publicNetworkAccessForQuery="$PublicNetworkAccessForQuery" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-MonitorDataCollectionEndpoint()
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
    $DataCollectionEndpointName,
    [Parameter(Mandatory = $false)]
    [string]
    $DataCollectionEndpointKind = "Linux",
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Data Collection Endpoint $DataCollectionEndpointName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DataCollectionEndpointName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    name="$DataCollectionEndpointName" `
    kind="$DataCollectionEndpointKind" `
    publicNetworkAccess="$PublicNetworkAccess" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-MonitorDataCollectionRule()
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
    $DataCollectionRuleName,
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceName,
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceResourceId,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Data Collection Endpoint $DataCollectionRuleName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DataCollectionRuleName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    dataCollectionRuleName="$DataCollectionRuleName" `
    logAnalyticsWorkspaceName="$LogAnalyticsWorkspaceName" `
    logAnalyticsWorkspaceResourceId="$LogAnalyticsWorkspaceResourceId" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-MonitorDataCollectionRuleAssociation()
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
    $DataCollectionEndpointResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $DataCollectionRuleResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $ScopedResourceId
  )

  Write-Debug -Debug:$true -Message "Deploy Data Collection Rule Association"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    dataCollectionEndpointResourceId="$DataCollectionEndpointResourceId" `
    dataCollectionRuleResourceId="$DataCollectionRuleResourceId" `
    scopedResourceId="$ScopedResourceId" `
    | ConvertFrom-Json

  return $output
}

function Deploy-MonitorPrivateLinkScopeResourceConnection()
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
    $PrivateLinkScopeName,
    [Parameter(Mandatory = $true)]
    [string]
    $ScopedResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $ScopedResourceName
  )

  Write-Debug -Debug:$true -Message "Connect Resource $ScopedResourceName to AMPLS $PrivateLinkScopeName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$PrivateLinkScopeName-$ScopedResourceName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    linkScopeName=$PrivateLinkScopeName `
    scopedResourceId=$ScopedResourceId `
    scopedResourceName=$ScopedResourceName `
    | ConvertFrom-Json

  return $output
}

function Deploy-MonitorPrivateLinkScope()
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
    $PrivateLinkScopeName,
    [Parameter(Mandatory = $false)]
    [string]
    $QueryAccessMode = "Open",
    [Parameter(Mandatory = $false)]
    [string]
    $IngestionAccessMode = "Open",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Azure Monitor Private Link Scope $PrivateLinkScopeName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$PrivateLinkScopeName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location=global `
    linkScopeName=$PrivateLinkScopeName `
    queryAccessMode=$QueryAccessMode `
    ingestionAccessMode=$IngestionAccessMode `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
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

function New-LogAnalyticsWorkspaceDataExport()
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
    $LogAnalyticsWorkspaceName,
    [Parameter(Mandatory=$true)]
    [string]
    $DataExportName,
    [Parameter(Mandatory=$true)]
    [string]
    $DestinationResourceId,
    [Parameter(Mandatory=$false)]
    [string[]]
    $TableNames = $null
  )
  Write-Debug -Debug:$true -Message "New-LogAnalyticsWorkspaceDataExport $LogAnalyticsWorkspaceName on $ResourceId"

  if ($null -eq $TableNames -or $TableNames.Count -eq 0)
  {
    New-AzOperationalInsightsDataExport
      -ResourceGroupName "$ResourceGroupName" `
      -WorkspaceName "$LogAnalyticsWorkspaceName" `
      -DataExportName "$DataExportName" `
      -ResourceId "$DestinationResourceId"
  }
  else
  {
    New-AzOperationalInsightsDataExport
      -ResourceGroupName "$ResourceGroupName" `
      -WorkspaceName "$LogAnalyticsWorkspaceName" `
      -DataExportName "$DataExportName" `
      -ResourceId "$DestinationResourceId" `
      -TableName $TableNames
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
