
function Get-AzureRegions()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false)]
    [string[]]
    $FilterDisplayNames = $null,
    [Parameter(Mandatory = $false)]
    [string[]]
    $FilterShortNames = $null
  )

  Write-Debug -Debug:$true -Message "Get Azure Regions"

  $locations = Get-AzLocation

  if ($FilterDisplayNames)
  {
    $locations = $locations | Where-Object {$_.DisplayName -in $FilterDisplayNames}
  }
  elseif ($FilterShortNames)
  {
    $locations = $locations | Where-Object {$_.Location -in $FilterShortNames}
  }

  return $locations
}