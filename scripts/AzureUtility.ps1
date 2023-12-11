function Remove-AzPackages()
{
  [CmdletBinding()]
  param()

  Get-Package | Where-Object { $_.Name -like 'Az*' } | ForEach-Object { Uninstall-Package -Name $_.Name -AllVersions }
}
