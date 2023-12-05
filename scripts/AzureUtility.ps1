function Get-Tags()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $EnvironmentName
  )

  # Replace : with - in the timestamp because : breaks ARM template tag parameter
  $timestampTagValue = (Get-Date -AsUTC -format s).Replace(":", "-") + "Z"
  $timestampTag = "timestamp=$timestampTagValue"

  $envTag = "env=$EnvironmentName"

  $tagsCli = @($envTag, $timestampTag)

  return $tagsCli
}

function Remove-AzPackages()
{
  [CmdletBinding()]
  param()

  Get-Package | Where-Object { $_.Name -like 'Az*' } | ForEach-Object { Uninstall-Package -Name $_.Name -AllVersions }
}
