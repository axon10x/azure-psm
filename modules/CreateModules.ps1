$powershellVersion = "7.0.0"
$author = "Patrick El-Azem"
$companyName = "ALFAADIN"
$projectUri = "https://github.com/plzm/azure-deploy"

$copyright = "(c) " + (Get-Date).Year + " Patrick El-Azem. All rights reserved."
$moduleVersion = "1.0.0"

$scriptsPath = ".\scripts\"
$azureModuleFolderName = "plzm.Azure"
$azureModuleFolderPath = ".\modules\" + $azureModuleFolderName
$azureModuleFileName = $azureModuleFolderName + ".psm1"
$azureModuleFilePath = $azureModuleFolderPath + "\" + $azureModuleFileName
$azureModuleFileContents = ""
$azureModuleManifestFileName = $azureModuleFolderName + ".psd1"
$azureModuleManifestFilPath = $azureModuleFolderPath + "\" + $azureModuleManifestFileName

if (!(Test-Path -Path $azureModuleFolderPath)) {
  New-Item -Path $azureModuleFolderPath -ItemType "Directory" -Force
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
