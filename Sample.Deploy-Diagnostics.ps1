# Fix the variables herein for your environment and just run it
# Note: this WILL deploy diagnostics settings per what you set. Know what you are doing before running this.
function Set-Diagnostics-Sample()
{
  # Make sure you are logged in and az account set -s is set to the correct subscription - or just specify the sub ID explicitly here
  $SubscriptionId = "$(az account show -o tsv --query 'id')"

  $ResourceGroupName = "rsg-test"
  $TemplateUri = "https://raw.githubusercontent.com/plzm/azure-deploy/main/template/diagnostic-settings.json"
  $DiagnosticsSettingName = "diag"
  $LogAnalyticsWorkspaceId = "/subscriptions/$SubscriptionId/resourceGroups/rsg-aa-ui-eus2-main/providers/microsoft.operationalinsights/workspaces/law-aa-ui-eus2-110"
  $StorageAccountId = "/subscriptions/$SubscriptionId/resourcegroups/rsg-aa-ui-eus2-main/providers/microsoft.storage/storageaccounts/saaauieus2130"
  $SendAllLogs = $false
  $SendAuditLogs = $true
  $SendMetrics = $true
  $AttemptFallback = $true

  Set-Diagnostics `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -TemplateUri $TemplateUri `
    -DiagnosticsSettingName $DiagnosticsSettingName `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId `
    -SendAllLogs $SendAllLogs `
    -SendAuditLogs $SendAuditLogs `
    -SendMetrics $SendMetrics `
    -AttemptFallback $AttemptFallback
}

# Fix the variables herein for your environment and just run it
# Note: this WILL DELETE diagnostics settings per what you set. Know what you are doing before running this.
function Remove-Diagnostics-Sample()
{
  # Make sure you are logged in and az account set -s is set to the correct subscription - or just specify the sub ID explicitly here
  $SubscriptionId = "$(az account show -o tsv --query 'id')"

  $ResourceGroupName = "rsg-test"
  $LogAnalyticsWorkspaceId = "/subscriptions/$SubscriptionId/resourceGroups/rsg-aa-ui-eus2-main/providers/microsoft.operationalinsights/workspaces/law-aa-ui-eus2-110"
  $StorageAccountId = "/subscriptions/$SubscriptionId/resourcegroups/rsg-aa-ui-eus2-main/providers/microsoft.storage/storageaccounts/saaauieus2130"

  Remove-Diagnostics `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId
}

function Set-Diagnostics()
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
    $DiagnosticsSettingName = "diag",
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
  Write-Debug -Debug:$true -Message "Set-Diagnostics"

  # ##################################################
  # Variables
  # plzm-Azure PS1 module with tons of functionality incl needed by this diagnostics harness - and yeah, you should look at the code and not just trust me before running this :)
  $moduleUrlRoot = "https://raw.githubusercontent.com/plzm/azure-deploy/main/modules/plzm.Azure/"
  # ##################################################

  # ##################################################
  # Download and import the plzm-Azure PS1 module
  Get-PlzmAzureModule -UrlRoot "$moduleUrlRoot"
  # ##################################################

  plzm.Azure\Deploy-DiagnosticsSettingsForAllResources `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -TemplateUri $TemplateUri `
    -DiagnosticsSettingName $DiagnosticsSettingName `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId `
    -SendAllLogs $SendAllLogs `
    -SendAuditLogs $SendAuditLogs `
    -SendMetrics $SendMetrics `
    -AttemptFallback $AttemptFallback
}

function Remove-Diagnostics()
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
  Write-Debug -Debug:$true -Message "Remove-Diagnostics"

  # ##################################################
  # Variables
  # plzm-Azure PS1 module
  $moduleUrlRoot = "https://raw.githubusercontent.com/plzm/azure-deploy/main/modules/plzm.Azure/"
  # ##################################################

  # ##################################################
  # Download and import the plzm-Azure PS1 module
  Get-PlzmAzureModule -UrlRoot "$moduleUrlRoot"
  # ##################################################

  plzm.Azure\Remove-DiagnosticsSettingsForAllResources `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId
}

function Get-PlzmAzureModule()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $UrlRoot
  )

  Write-Debug -Debug:$true -Message "Get-PlzmAzureModule"

  $moduleName = "plzm.Azure"
  $localFolderPath = "./modules/$moduleName/"
  $psm1FileName = "$moduleName.psm1"
  $psd1FileName = "$moduleName.psd1"

  if (!(Test-Path -Path $localFolderPath))
  {
    New-Item -Path $localFolderPath -ItemType "Directory" -Force | Out-Null
  }

  # PSM1 file
  $url = ($UrlRoot + $psm1FileName)
  Invoke-WebRequest -Uri "$url" -OutFile ($localFolderPath + $psm1FileName)

  # PSD1 file
  $url = ($UrlRoot + $psd1FileName)
  Invoke-WebRequest -Uri "$url" -OutFile ($localFolderPath + $psd1FileName)

  Import-Module "$localFolderPath" -Force

  Write-Debug -Debug:$true -Message "Module $moduleName imported with version $((Get-Module $moduleName).Version)"
  plzm.Azure\Get-Timestamp
}