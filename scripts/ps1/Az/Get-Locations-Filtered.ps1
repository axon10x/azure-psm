$displayNames = @("East US", "West US")
$locations = Get-AzLocation
$filteredLocations = @()

ForEach ($displayName in $displayNames) {$filteredLocations += $locations | Where-Object {$_.DisplayName -eq $displayName}}

$filteredLocations
