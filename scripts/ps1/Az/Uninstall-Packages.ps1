# How to uninstall packages with a wildcard approach rather than one at a time!

Get-Package | Where-Object { $_.Name -like 'Az*' } | ForEach-Object { Uninstall-Package -Name $_.Name -AllVersions }