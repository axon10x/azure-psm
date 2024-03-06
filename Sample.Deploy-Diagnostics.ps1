<#

*** TEST THIS IN A NON-PRODUCTION ENVIRONMENT FIRST ***
*** KNOW WHAT YOU ARE DOING BEFORE RUNNING THIS ***

Azure Policy remediation is usually preferable to script-based (since policy is a background engine that runs periodically and user with enough permission has to take specific steps to avoid policy effects, whereas script is point-in-time unless automated to run periodically).

This script uses the plzm.Azure Powershell module built/available in this repo. The module contains functionality that can take care of all the diagnostics controls, as follows.

- User designates a subscription and, optionally, a resource group, as scope
- User designates sink(s) - can specify a Log Analytics workspace and/or a storage account (either individually or both together are supported)
  - Event Hubs or Partner Solutions are not supported at this time
- User designates diagnostics to put on each Azure resource, as follows:
  - All logs yes/no
  - Audit logs yes/no
  - Metrics yes/no
- User designates whether a fallback strategy should be used, so that if an Azure resource does not support the user-specified diagnostics configuration, the script progressively falls back to "safer" diagnostics configurations and tries again (some resources types do not support the audit logs category group, or do not support metrics, etc.)
  - This varied support is why there is an Azure Policy initiative, which contains many individual Azure Policy definitions, one per resource type
- Above designations are done via simple variables/parameters (see below)
- User runs script
- Script iterates through all Azure resources in the scope (subscription or resource group)
- For each resource, script proceeds as follows -
  - Attempt to deploy the user's specified diagnostics configuration
  - If that fails, AND if user specified fallback strategy, progressively fall back to "safer" diagnostics strategies, try again, and if all fail, return an error for that resource and then continue
- My scripts support storage account child resources and equip those with the required separate diagnostic settings - i.e. blob, file, queue, table services. A storage account + children would have five distinct diagnostic settings.

The above can be used both on a local level (a product or service team in its environment) or at a more global level across resource groups and/or subscriptions. This can easily be adapted into CI/CD DevOps pipelines.

This approach is not limited to specific Azure resource types - will work with anything it finds and adapt to what each resource type supports.

The script is opinionated in that, for example, the fallback strategy (if elected by user) will "degrade" from audit logs (if not supported) to all logs, before going to no logs, under the presumption that logging more is preferable to not logging at all.

There is also a "remove all" counterpart, since good practice in CI/CD/DevOps/infrastructure means each deploy tool has a correlated remove tool, so that as teams test something like this, it's very easy for them to do a deploy, realize they want to change something, then un-deploy in one line of code, etc.

The remove script does not need diagnostic setting names. Instead, if you specify the sink(s) in question, it will iterate through each resource's diagnostic settings (since an Azure resource can have up to 20 total diagnostic settings, or more in the case of storage accounts) and only remove those which correspond to the sink(s) user specifies. In this way, existing diagnostic settings which point at other than the DSR sinks are preserved, and user diagnostics for other purposes (like operational dashboards and alerts) continue as is.

The script uses an ARM template, also in this repo, for deploying diagnostic settings. My ARM template includes logic to handle multiple sinks etc.

Users can specify diagnostic setting name when deploying, but the diagnostic setting name really doesn't matter. It can be used for specific retrieval or removal, but the removal script goes by what sinks you want to remove, finds matching diagnostic settings, and removes those. In that way, teams can have various diagnostic settings pointing to different sinks, but only the settings matching the specified sinks will be removed, so as not to disrupt other diagnostic settings.

Sample script here which shows a simple scenario for both deploy and remove - the user would adapt Set-Diagnostics-Sample() and Remove-Diagnostics-Sample() with their specific subscription and other resource IDs. Everything else, including Powershell module download and local install, is handled for the user.
#>

# Fix the variables herein for your environment and run it
# Note: this WILL deploy diagnostics settings per what you set. Know what you are doing before running this.
function Set-Diagnostics-Sample()
{
  # Make sure you are logged in and az account set -s is set to the correct subscription - or just specify the sub ID explicitly here
  $SubscriptionId = "$(az account show -o tsv --query 'id')"

  # Resource Group where your resources are that you want to equip with diagnostics settings
  $ResourceGroupNameTarget = "rsg-test"
  # You can use my ARM template for diagnostics setting, or substitute in your own
  $TemplateUri = "https://raw.githubusercontent.com/plzm/azure-deploy/main/template/diagnostic-settings.json"
  # You can substitute in your own diagnostic setting name. It doesn't matter for these scripts, but can be used for specific retrieval or removal.
  $DiagnosticsSettingName = "diag"

  # Sink(s) - adjust these to your environment
  $ResourceGroupNameSinks = "rsg-sinks"
  $LogAnalyticsWorkspaceName = "law-sink"
  $StorageAccountName = "sasink"
  $LogAnalyticsWorkspaceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupNameSinks/providers/microsoft.operationalinsights/workspaces/$LogAnalyticsWorkspaceName"
  $StorageAccountId = "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupNameSinks/providers/microsoft.storage/storageaccounts/$StorageAccountName"

  $SendAllLogs = $false
  $SendAuditLogs = $true
  $SendMetrics = $true
  $AttemptFallback = $true

  Set-Diagnostics `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupNameTarget `
    -TemplateUri $TemplateUri `
    -DiagnosticsSettingName $DiagnosticsSettingName `
    -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId `
    -StorageAccountId $StorageAccountId `
    -SendAllLogs $SendAllLogs `
    -SendAuditLogs $SendAuditLogs `
    -SendMetrics $SendMetrics `
    -AttemptFallback $AttemptFallback
}

# Fix the variables herein for your environment and run it
# Note: this WILL DELETE diagnostics settings per what you set. Know what you are doing before running this.
function Remove-Diagnostics-Sample()
{
  # Make sure you are logged in and az account set -s is set to the correct subscription - or just specify the sub ID explicitly here
  $SubscriptionId = "$(az account show -o tsv --query 'id')"

  # Resource Group where your resources are from which you want to remove diagnostics settings
  $ResourceGroupNameTarget = "rsg-test"

  # Sink(s)
  $ResourceGroupNameSinks = "rsg-sinks"
  $LogAnalyticsWorkspaceName = "law-sink"
  $StorageAccountName = "sasink"
  $LogAnalyticsWorkspaceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupNameSinks/providers/microsoft.operationalinsights/workspaces/$LogAnalyticsWorkspaceName"
  $StorageAccountId = "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupNameSinks/providers/microsoft.storage/storageaccounts/$StorageAccountName"

  Remove-Diagnostics `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupNameTarget `
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
    $ResourceGroupNameTarget = "",
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
    -ResourceGroupName $ResourceGroupNameTarget `
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
    $ResourceGroupNameTarget = "",
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
    -ResourceGroupName $ResourceGroupNameTarget `
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