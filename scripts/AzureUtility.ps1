function Get-TagsForArmTemplate()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Get-TagsForArmTemplate: $Tags"

  $tagsObject = @{}

  if ($Tags)
  {
    $tagKVPairs = $Tags.Split(",")
    foreach ($tagKVPair in $tagKVPairs)
    {
      $tagKVArray = $tagKVPair.Split("=")
      $tagsObject[$tagKVArray[0]] = $tagKVArray[1]
    }
  }

  $tagsForArm = ConvertTo-Json -InputObject $tagsObject -Compress
  $tagsForArm = $tagsForArm.Replace('"', '''')
  $tagsForArm = "`"$tagsForArm`""

  return $tagsForArm
}

function Remove-AzPackages()
{
  Get-Package | Where-Object { $_.Name -like 'Az*' } | ForEach-Object { Uninstall-Package -Name $_.Name -AllVersions }
}
