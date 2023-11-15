function Get-CurrentPythonVersion
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [bool]
    $IncludeRevision = $false,
    [Parameter(Mandatory=$false)]
    [bool]
    $IncludePunctuation = $true
  )

  $version = (Invoke-Expression "python --version").Replace("Python ", "")

  if (!$IncludeRevision)
  {
    $version = $version.Substring(0, $version.LastIndexOf("."))
  }

  if (!$IncludePunctuation)
  {
    $version = $version.Replace(".", "")
  }

  return $version
}

function Invoke-PipUpgrade()
{
  [CmdletBinding()]
  param
  (
  )

  Write-Debug -Debug:$true -Message "Invoke-PipUpgrade"

  $expr = "python -m pip install --upgrade pip" + `
   "--trusted-host pypi.org " + `
   "--trusted-host pypi.python.org " + `
   "--trusted-host files.pythonhosted.org"
  
  Write-Debug -Debug:$true -Message "Running pip install command:"
  Write-Debug -Debug:$true -Message $expr

  Invoke-Expression $expr


  $expr = "pip install --upgrade setuptools" + `
     "--trusted-host pypi.org " + `
     "--trusted-host pypi.python.org " + `
     "--trusted-host files.pythonhosted.org"

    Write-Debug -Debug:$true -Message "Running pip install command:"
    Write-Debug -Debug:$true -Message $expr
  
    Invoke-Expression $expr
}

function Invoke-PipInstallPackage()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $Package,
    [Parameter(Mandatory=$false)]
    [string]
    $Version = "",
    [Parameter(Mandatory=$false)]
    [string]
    $Comparison="=="
  )

  Write-Debug -Debug:$true -Message "Invoke-PipInstallPackage :: $Package :: $Version :: $Comparison"

  $predicate = ""

  if ($Version -and $Comparison)
  {
    $predicate = $Comparison + $Version
  }

  $expr = "pip install --upgrade " + $Package + $predicate + " " + `
   "--trusted-host pypi.org " + `
   "--trusted-host pypi.python.org " + `
   "--trusted-host files.pythonhosted.org"

  Write-Debug -Debug:$true -Message "Running pip install command:"
  Write-Debug -Debug:$true -Message $expr

  Invoke-Expression $expr
}

function Invoke-PipInstallRequirements()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [string]
    $RequirementsFilePath = "requirements.txt",
    [Parameter(Mandatory=$false)]
    [string]
    $TargetPath = ""
  )

  Write-Debug -Debug:$true -Message "Invoke-PipInstallRequirements :: $RequirementsFilePath :: $TargetPath"

  if ($TargetPath)
  {
    $target = "--target=""" + $TargetPath + """ "
  }
  else
  {
    $target = ""
  }

  $expr = "pip install --upgrade " + `
    $target + `
    "-r " + $RequirementsFilePath + " " + `
     "--trusted-host pypi.org " + `
     "--trusted-host pypi.python.org " + `
     "--trusted-host files.pythonhosted.org"

  Write-Debug -Debug:$true -Message "Running pip install command:"
  Write-Debug -Debug:$true -Message $expr

  Invoke-Expression $expr
}


function Remove-PyCache()
{
  Get-ChildItem * -Include "__pycache__" -Recurse | Remove-Item -Recurse -Force
}