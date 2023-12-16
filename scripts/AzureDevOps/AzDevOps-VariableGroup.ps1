$debug = $false

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
  Write-Debug -Debug:$true -Message "Get-VarGroupId()"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  return $vgId
}

function Test-VarGroupVarExists()
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
  Write-Debug -Debug:$true -Message "Test-VarGroupVarExists()"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = Set-VarGroup -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName" 

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "varName = $VarName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  # We don't use a JMESPath --query here in case some var names have special characters like :, which crashes the query
  # So instead we get all (wasteful but...) into a Powershell hashtable and then see if the var exists by key lookup on the var name
  $varMatches = "$(az pipelines variable-group variable list --org "$azdoOrgUrl" --project "$AzdoProjectName" --group-id "$vgId")" | ConvertFrom-Json -AsHashtable
  Write-Debug -Debug:$true -Message "varMatches = $varMatches"

  $varExists = ( $null -ne $varMatches[$VarName])
  Write-Debug -Debug:$true -Message "varExists = $varExists"

  return $varExists
}

function Get-VarGroupVars()
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
  Write-Debug -Debug:$true -Message "Get-VarGroupVars()"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  $varsJson = "$(az pipelines variable-group variable list --org $azdoOrgUrl --project $AzdoProjectName --group-id $vgId)"

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  Write-Debug -Debug:$true -Message "varsJson = $varsJson"

  $vars = $varsJson | ConvertFrom-Json -AsHashtable

  return $vars
}

function Get-VarGroupVar()
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
  Write-Debug -Debug:$true -Message "Get-VarGroupVar()"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"

  $varMatches = "$(az pipelines variable-group variable list --org "$azdoOrgUrl" --project "$AzdoProjectName" --group-id "$vgId")" | ConvertFrom-Json -AsHashtable
  Write-Debug -Debug:$true -Message "varMatches = $varMatches"

  $var = $varMatches[$VarName]

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "varName = $VarName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  Write-Debug -Debug:$true -Message ("var = " + $var.value)

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
  Write-Debug -Debug:$true -Message "Set-VarGroup() $VarGroupName"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "accessibleByAllPipelines = $AccessibleByAllPipelines"
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
    az pipelines variable-group create --org $azdoOrgUrl --project $AzdoProjectName --name $VarGroupName --authorize $AccessibleByAllPipelines --variables foo=bar
  }

  $vgId = "$(az pipelines variable-group list --org $azdoOrgUrl --project $AzdoProjectName -o tsv --query "[?name=='$VarGroupName'].id")"
  Write-Debug -Debug:$true -Message "vgId = $vgId"
  return $vgId
}

function Set-VarGroupVar()
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
    [Parameter(Mandatory=$false)]
    [string]
    $VarValue="",
    [Parameter(Mandatory=$false)]
    [string]
    $Secret="false",
    [Parameter(Mandatory=$false)]
    [boolean]
    $Overwrite=$true
  )
  Write-Debug -Debug:$true -Message "Set-VarGroupVar() $VarName"

  $azdoOrgUrl = "https://dev.azure.com/$AzdoOrgName"

  $vgId = Set-VarGroup -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName"

  Write-Debug -Debug:$true -Message "azdoOrgName = $AzdoOrgName"
  Write-Debug -Debug:$true -Message "azdoProjectName = $AzdoProjectName"
  Write-Debug -Debug:$true -Message "varGroupName = $VarGroupName"
  Write-Debug -Debug:$true -Message "varName = $VarName"
  Write-Debug -Debug:$true -Message "azdoOrgUrl = $azdoOrgUrl"
  Write-Debug -Debug:$true -Message "vgId = $vgId"

  $varExists = Test-VarGroupVarExists -azdoOrgName "$AzdoOrgName" -azdoProjectName "$AzdoProjectName" -varGroupName "$VarGroupName" -varName "$varName"

  if ($varExists)
  {
    Write-Debug "Variable exists: $VarName"

    if ($Overwrite)
    {
      Write-Debug -Debug:$true -Message "Variable exists - update: $VarName"
      az pipelines variable-group variable update `
        --org "$azdoOrgUrl" `
        --project "$AzdoProjectName" `
        --group-id "$vgId" `
        --name "$VarName" `
        --secret "$Secret" `
        --value "$VarValue"
    }
    else
    {
      Write-Debug -Debug:$true -Message "Variable exists but overwrite is off, no op: $VarName"
    }
  }
  else
  {
    Write-Debug -Debug:$true -Message "Create variable $VarName"
    az pipelines variable-group variable create `
    --org "$azdoOrgUrl" `
    --project "$AzdoProjectName" `
    --group-id "$vgId" `
    --name "$VarName" `
    --secret "$Secret" `
    --value "`"$VarValue`""
  }
}
