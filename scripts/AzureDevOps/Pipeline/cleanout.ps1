param
(
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountName,
  [Parameter(Mandatory = $true)]
  [string]
  $DataFunctionsFilePath
)

. $DataFunctionsFilePath

$SubscriptionName = $(az account show -o tsv --query 'name')

$containerQuery = "[?!(starts_with(name, 'bak') || starts_with(name, 'azure-webjobs') || starts_with(name, 'insights'))].name"
$containerNames = $(az storage container list --account-name $StorageAccountName --auth-mode login -o tsv --query $containerQuery)
$queueNames = $(az storage queue list --account-name $StorageAccountName --auth-mode login -o tsv --query '[].name')
$tableQuery = "[?!(name == 'SchemasTable' || starts_with(name, 'bak'))].name"
$tableNames = $(az storage table list --account-name $StorageAccountName --auth-mode login -o tsv --query $tableQuery)

Remove-StorageObjects `
  -SubscriptionName $SubscriptionName `
  -StorageAccountName $StorageAccountName `
  -ContainerNames $containerNames `
  -QueueNames $queueNames `
  -TableNames $tableNames
