# Make sure $env:AZURE_DEVOPS_EXT_PAT is set correctly
function Get-VarGroupId()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  return $vgId
}

function Get-VarGroupVarExists()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarName
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = setVG -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName" 

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "VarName = $VarName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  # We don't use a JMESPath --query here in case var names include special characters
  # Instead we get all into a Powershell hashtable and then see if the var exists by key lookup on the var name
  $varMatches = "$(az pipelines variable-group variable list --org "$azdoOrgUrl" --project "$AzdoProjectName" --group-id "$vgId")" | ConvertFrom-Json -AsHashtable
  Write-Debug -Debug:$true -Message "varMatches = $varMatches"

  $varExists = ( $null -ne $varMatches[$VarName])
  Write-Debug -Debug:$true -Message "varExists = $varExists"

  return $varExists
}

function Get-VarGroupVariables()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  $varsJson = "$(az pipelines variable-group variable list --org $azdoOrgUrl --project $AzdoProjectName --group-id $vgId)"

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  Write-Debug -Debug:$true -Message "varsJson = $varsJson"

  $vars = $varsJson | ConvertFrom-Json -AsHashtable

  return $vars
}

function Get-VarGroupVariable()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarName
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  $varMatches = "$(az pipelines variable-group variable list --org "$azdoOrgUrl" --project "$AzdoProjectName" --group-id "$vgId")" | ConvertFrom-Json -AsHashtable
  Write-Debug -Debug:$true -Message "varMatches = $varMatches"

  $var = $varMatches[$VarName]

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "VarName = $VarName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  Write-Debug -Debug:$true -Message "var = $var"

  return $var.value
}

function Set-VarGroup()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName,
    [Parameter(Mandatory=$false)]
    [bool]
    $AccessibleByAllPipelines=$false
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "AccessibleByAllPipelines = $AccessibleByAllPipelines"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"

  $vgMatches = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName --query "[?name=='$VarGroupName'].id")" | ConvertFrom-Json
  Write-Debug -Debug:$true -Message "vgMatches = $vgMatches"

  $vgExists = $vgMatches.Length -gt 0
  Write-Debug -Debug:$true -Message "vgExists = $vgExists"

  if ($vgExists)
  {
    Write-Debug -Debug:$true -Message "Variable Group $VarGroupName already exists, no op"
  }
  else
  {
    Write-Debug -Debug:$true -Message "Create Variable Group $VarGroupName"
    az pipelines variable-group create --org $azdoOrgUrl --project $AzdoProjectName --name $VarGroupName --authorize $AccessibleByAllPipelines --variables foo=bar --verbose
  }

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  return $vgId
}

function Set-VarGroupVariable()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoOrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $AzdoProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarName,
    [Parameter(Mandatory=$true)]
    [string]
    $VarValue,
    [Parameter(Mandatory=$false)]
    [string]
    $IsSecret="false"
  )
  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = setVG -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName"

  Write-Debug -Debug:$true -Message "AzdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "AzdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "VarGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "VarName = $VarName"
  Write-Debug -Debug:$true -Message "VarValue = $VarValue"
  Write-Debug -Debug:$true -Message "IsSecret = $IsSecret"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  $varExists = getVGVarExists -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName" -varName "$VarName"
  Write-Debug -Debug:$true -Message "varExists = $varExists"

  if ($varExists)
  {
    Write-Debug -Debug:$true -Message "Update variable $VarName"
    az pipelines variable-group variable update `
      --org "$azdoOrgUrl" `
      --project "$AzdoProjectName" `
      --group-id "$vgId" `
      --name "$VarName" `
      --secret "$IsSecret" `
      --value "$VarValue" `
      --verbose
  }
  else
  {
    Write-Debug -Debug:$true -Message "Create variable $VarName"
    az pipelines variable-group variable create `
    --org "$azdoOrgUrl" `
    --project "$AzdoProjectName" `
    --group-id "$vgId" `
    --name "$VarName" `
    --secret "$IsSecret" `
    --value "$VarValue" `
    --verbose
  }
}
