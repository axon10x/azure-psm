$powershellVersion = "7.0"
$author = "Patrick El-Azem"
$companyName = "AXON10 LLC"
$projectUri = "https://github.com/plzm/azure-deploy"

$copyright = "(c) " + (Get-Date).Year + " " + $companyName + ". All rights reserved."

$scriptsPath = ".\scripts\"
$azureModuleName = "plzm.Azure"
$azureModuleFolderPath = ".\modules\" + $azureModuleName
$azureModuleFileName = $azureModuleName + ".psm1"
$azureModuleFilePath = $azureModuleFolderPath + "\" + $azureModuleFileName
$azureModuleFileContents = ""
$azureModuleManifestFileName = $azureModuleName + ".psd1"
$azureModuleManifestFilPath = $azureModuleFolderPath + "\" + $azureModuleManifestFileName

$moduleVersion = "2.0"

if (!(Test-Path -Path $azureModuleFolderPath))
{
  Write-Debug -Debug:$true -Message "Create new module folder $azureModuleFolderPath and set moduleVersion to $moduleVersion"

  New-Item -Path $azureModuleFolderPath -ItemType "Directory" -Force
}
else
{
  # We have an existing module folder. Let's try to import the existing module to get its version and increment it by 0.1 (i.e. increment minor version by 1)

  Write-Debug -Debug:$true -Message "Found existing module folder $azureModuleFolderPath"

  Import-Module -Name $azureModuleFolderPath -Force -ErrorAction SilentlyContinue
  $module = Get-Module $azureModuleName -ErrorAction SilentlyContinue

  if ($module)
  {
    $moduleVersion = $module.Version.Major.ToString() + "." + ($module.Version.Minor + 1).ToString()
    Write-Debug -Debug:$true -Message "Found existing module and setting new version to $moduleVersion"
  }
  else
  {
    Write-Debug -Debug:$true -Message "Could not get module, setting new version to $moduleVersion"
  }
}

Get-ChildItem -Path $scriptsPath -File -Filter *.ps1 | ForEach-Object {
  # Get file contents as a string, not an array
  $fileContents = Get-Content -Path $_.FullName -Raw

  $azureModuleFileContents += (
    "# ##################################################" + "`n" +
    "# " + $_.Name + "`n" +
    "# ##################################################" + "`n`n" +
    $fileContents + "`n`n"
  )
}

$azureModuleFileContents | Out-File -FilePath $azureModuleFilePath -Encoding utf8

New-ModuleManifest `
  -Path $azureModuleManifestFilPath `
  -RootModule $azureModuleFilePath `
  -PowerShellVersion $powershellVersion `
  -ModuleVersion $moduleVersion `
  -Author $author `
  -CompanyName $companyName `
  -Copyright $copyright `
  -ProjectUri $projectUri
