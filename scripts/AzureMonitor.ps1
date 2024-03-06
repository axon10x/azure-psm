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
    $AzureAppPushReceivers = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Action Group $ActionGroupName"

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

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
    tags=$tagsForTemplate `
    | ConvertFrom-Json

  return $output
}

function Deploy-DiagnosticsSettingsForAllResources()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = "",
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateUri,
    [Parameter(Mandatory = $false)]
    [string]
    $DiagnosticsSettingName = "plzm-azure-diag",
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = "",
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccountId = "",
    [Parameter(Mandatory = $false)]
    [bool]
    $SendAllLogs = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendAuditLogs = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendMetrics = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $AttemptFallback = $false
  )
  Write-Debug -Debug:$true -Message "Deploy-DiagnosticsSettingsForAllResources :: ResourceGroupName = $ResourceGroupName, LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId, StorageAccountId = $StorageAccountId"

  $resources = Get-Resources -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -AddChildResources $true

  foreach ($resource in $resources)
  {
    Deploy-DiagnosticsSetting `
      -SubscriptionId $SubscriptionId `
      -ResourceGroupName $resource.resourceGroup `
      -TemplateUri $TemplateUri `
      -ResourceId $resource.id `
      -DiagnosticsSettingName $DiagnosticsSettingName `
      -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
      -StorageAccountId $StorageAccountId `
      -SendAllLogs $SendAllLogs `
      -SendAuditLogs $SendAuditLogs `
      -SendMetrics $SendMetrics `
      -AttemptFallback $AttemptFallback
  }
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
    [Parameter(Mandatory = $false)]
    [string]
    $LogAnalyticsWorkspaceId,
    [Parameter(Mandatory = $false)]
    [string]
    $StorageAccountId,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendAllLogs = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendAuditLogs = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendMetrics = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $AttemptFallback = $false
  )

  Write-Debug -Debug:$true -Message "Deploy Diagnostics Setting $DiagnosticsSettingName to ResourceId $ResourceId"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DiagnosticsSettingName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    resourceId="$ResourceId" `
    diagnosticsSettingName="$DiagnosticsSettingName" `
    logAnalyticsWorkspaceId="$LogAnalyticsWorkspaceId" `
    storageAccountId="$StorageAccountId" `
    sendAllLogs=$SendAllLogs `
    sendAuditLogs=$SendAuditLogs `
    sendMetrics=$SendMetrics `
    | ConvertFrom-Json

    # 2>nul `

  if (!$output)
  {
    $output = "ERROR!"

    if ($AttemptFallback)
    {
      if ($SendAuditLogs -and !$SendAllLogs)
      {
        $SendAuditLogs = $false
        $SendAllLogs = $true
      }
      elseif ($SendAllLogs)
      {
        $SendAuditLogs = $false
        $SendAllLogs = $false
      }
      elseif (!$SendAllLogs -and !$SendAuditLogs -and $SendMetrics)
      {
        $SendMetrics = $false
      }
      else
      {
        $AttemptFallback = $false
      }

      $output = Deploy-DiagnosticsSetting `
        -SubscriptionId $SubscriptionId `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri $TemplateUri `
        -ResourceId $ResourceId `
        -DiagnosticsSettingName $DiagnosticsSettingName `
        -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
        -StorageAccountId $StorageAccountId `
        -SendAllLogs $SendAllLogs `
        -SendAuditLogs $SendAuditLogs `
        -SendMetrics $SendMetrics `
        -AttemptFallback $AttemptFallback
    }
  }

  return $output
}

function Deploy-LogAnalyticsWorkspace()
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

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

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
    tags=$tagsForTemplate `
    | ConvertFrom-Json

  return $output
}

function Deploy-MetricAlert()
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
    $MetricAlertName,
    [Parameter(Mandatory = $true)]
    [int]
    $Severity,
    [Parameter(Mandatory = $true)]
    [string]
    $TargetResourceType,
    [Parameter(Mandatory = $true)]
    [string]
    $TargetResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $EvaluationFrequency,
    [Parameter(Mandatory = $true)]
    [string]
    $WindowSize,
    [Parameter(Mandatory = $false)]
    [bool]
    $AutoMitigate = $true,
    [Parameter(Mandatory = $true)]
    [string]
    $MetricNamespace,
    [Parameter(Mandatory = $true)]
    [string]
    $MetricName,
    [Parameter(Mandatory = $true)]
    [string]
    $Operator,
    [Parameter(Mandatory = $true)]
    [long]
    $Threshold,
    [Parameter(Mandatory = $true)]
    [string]
    $TimeAggregation,
    [Parameter(Mandatory = $true)]
    [string]
    $ActionGroupId,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Metric Alert $MetricAlertName"

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$MetricAlertName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    metricAlertName="$MetricAlertName" `
    severity="$Severity" `
    targetResourceType="$TargetResourceType" `
    targetResourceId="$TargetResourceId" `
    evaluationFrequency="$EvaluationFrequency" `
    windowSize="$WindowSize" `
    autoMitigate="$AutoMitigate" `
    metricNamespace="$MetricNamespace" `
    metricName="$MetricName" `
    operator="$Operator" `
    threshold="$Threshold" `
    timeAggregation="$TimeAggregation" `
    actionGroupId="$ActionGroupId" `
    tags=$tagsForTemplate `
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

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

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
    tags=$tagsForTemplate `
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
    $LogAnalyticsWorkspaceId,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Data Collection Endpoint $DataCollectionRuleName"

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DataCollectionRuleName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    dataCollectionRuleName="$DataCollectionRuleName" `
    logAnalyticsWorkspaceName="$LogAnalyticsWorkspaceName" `
    logAnalyticsWorkspaceId="$LogAnalyticsWorkspaceId" `
    tags=$tagsForTemplate `
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

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

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
    tags=$tagsForTemplate `
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
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccountId = "",
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName
  )
  Write-Debug -Debug:$true -Message "Get-DiagnosticsSettingsForResource $ResourceName"

  [System.Collections.ArrayList]$result = @()

  if ($LogAnalyticsWorkspaceId -and $StorageAccountId)
  {
    $query = "[?(workspaceId=='" + $LogAnalyticsWorkspaceId + "' && storageAccountId=='" + $StorageAccountId + "')].{name:name, id:id}"
  }
  elseif ($LogAnalyticsWorkspaceId)
  {
    $query = "[?(workspaceId=='" + $LogAnalyticsWorkspaceId + "')].{name:name, id:id}"
  }
  elseif ($StorageAccountId)
  {
    $query = "[?(storageAccountId=='" + $StorageAccountId + "')].{name:name, id:id}"
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
    $LogAnalyticsWorkspaceId = "",
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccountId = ""
  )
  Write-Debug -Debug:$true -Message "Get-DiagnosticsSettingsForSub $ResourceName"

  [System.Collections.ArrayList]$result = @()

  if ($LogAnalyticsWorkspaceId)
  {
    $query = "(value)[?(workspaceId=='" + $LogAnalyticsWorkspaceId + "')].{name:name, id:id}"
  }
  elseif ($StorageAccountId)
  {
    $query = "(value)[?(storageAccountId=='" + $StorageAccountId + "')].{name:name, id:id}"
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
    $ResourceId
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSetting $DiagnosticsSettingName from $ResourceId"

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
    $ResourceGroupName = "",
    [Parameter(Mandatory=$false)]
    [string]
    $LogAnalyticsWorkspaceId = "",
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccountId = ""
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSettingsForAllResources :: ResourceGroupName = $ResourceGroupName, LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId"

  $resources = Get-Resources -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -AddChildResources $true

  foreach ($resource in $resources)
  {
    Remove-DiagnosticsSettingsForResource `
      -SubscriptionId $SubscriptionId `
      -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
      -StorageAccountId $StorageAccountId `
      -ResourceId $resource.id `
      -ResourceName $resource.name
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
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccountId = "",
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName
  )
  Write-Debug -Debug:$true -Message "Remove-DiagnosticsSettingsForResource :: ResourceId = $ResourceId"

  $settings = Get-DiagnosticsSettingsForResource `
    -SubscriptionId $SubscriptionId `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId `
    -ResourceId $ResourceId `
    -ResourceName $ResourceName

  if ($settings.Count -gt 0)
  {
    foreach ($setting in $settings)
    {
      Remove-DiagnosticsSetting `
        -SubscriptionId $SubscriptionId `
        -DiagnosticsSettingName $setting.name `
        -ResourceId $ResourceId
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
