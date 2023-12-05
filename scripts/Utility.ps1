function New-RandomString
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false)]
    [Int]
    $Length = 10
  )

  return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))
}

function Remove-AzPackages()
{
  [CmdletBinding()]
  param()

  Get-Package | Where-Object { $_.Name -like 'Az*' } | ForEach-Object { Uninstall-Package -Name $_.Name -AllVersions }
}

