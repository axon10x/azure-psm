. ./vg.functions.ps1

$azdoOrgName = "MyAzdoOrgName"
$azdoProjectName = "MyAzdoProjectName"

$varGroupSource = "vg-source"
$varGroupTargets = @( "vg-target1", "vg-target2" )

$vars = Get-VarGroupVars -AzdoOrgName $azdoOrgName -AzdoProjectName $azdoProjectName -VarGroupName $varGroupSource
$varNames = $vars.Keys

foreach ($varGroupTarget in $varGroupTargets)
{
  foreach ($varName in $varNames)
  {
    $varValueSource = Get-VarGroupVar `
      -AzdoOrgName $azdoOrgName `
      -AzdoProjectName $azdoProjectName `
      -VarGroupName $varGroupSource `
      -VarName $varName
  
    Set-VarGroupVar `
      -AzdoOrgName $azdoOrgName `
      -AzdoProjectName $azdoProjectName `
      -VarGroupName $varGroupTarget `
      -VarName $varName `
      -VarValue $varValueSource `
      -Secret $false `
      -Overwrite $false
  }
}
