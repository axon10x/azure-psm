function New-VirtualEnvironment()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [string]
    $VEnvPath = "venv"
  )

  if (!(Test-Path $VEnvPath))
  {
    Write-Debug -Debug:$true -Message "Create virtual environment $VEnvPath"

    $expr = "python -m venv " + $VEnvPath
    Invoke-Expression $expr

    Copy-Item -Path "scripts/pip.ini" -Destination $VEnvPath -Force
  }
  else
  {
    Write-Debug -Debug:$true -Message "Virtual environment $VEnvPath already exists, exiting with no changes."
  }
}

function Enter-VirtualEnvironment()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [string]
    $VEnvPath = "venv"
  )

  if ($VEnvPath.StartsWith("./")) { $VEnvPath = $VEnvPath.Replace("./", "") }
  $psPath = "./" + $VEnvPath

  Write-Debug -Debug:$true -Message "Activate virtual environment $VEnvPath"
  if (Test-Path ($psPath + "/bin"))
  {
    $expr = $psPath + "/bin/Activate.ps1"
  }
  elseif (Test-Path ($psPath + "/Scripts"))
  {
    $expr = $psPath + "/Scripts/Activate.ps1"
  }

  Invoke-Expression $expr
}

function Exit-VirtualEnvironment()
{
  [CmdletBinding()]
  param
  (
  )

  Write-Debug -Debug:$true -Message "Exit virtual environment"
  $expr = "deactivate"
  Invoke-Expression $expr
}

function Remove-VirtualEnvironment()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [string]
    $VEnvPath = "venv"
  )

  if (Test-Path $VEnvPath)
  {
    Write-Debug -Debug:$true -Message "Delete virtual environment with path $VEnvPath"
    Remove-Item -Recurse -Force -Path $VEnvPath
  }
  else
  {
    Write-Debug -Debug:$true -Message "Path $VenvPath not found. Exiting with no change."
  }
}
