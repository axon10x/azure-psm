param
(
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountNameSource,
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountNameSink,
  [Parameter(Mandatory = $true)]
  [string]
  $DataFunctionsFilePath
)

. $DataFunctionsFilePath

$SubscriptionName = $(az account show -o tsv --query 'name')

$containerQuery = "[?!(starts_with(name, 'bak') || starts_with(name, 'azure-webjobs') || starts_with(name, 'insights'))].name"
$containerNames = $(az storage container list --account-name $StorageAccountNameSource --auth-mode login -o tsv --query $containerQuery)
$queueNames = $(az storage queue list --account-name $StorageAccountNameSource --auth-mode login -o tsv --query '[].name')
$tableQuery = "[?!(name == 'SchemasTable' || starts_with(name, 'bak'))].name"
$tableNames = $(az storage table list --account-name $StorageAccountNameSource --auth-mode login -o tsv --query $tableQuery)

New-StorageObjects `
  -SubscriptionName $SubscriptionName `
  -StorageAccountName $StorageAccountNameSink `
  -ContainerNames $containerNames `
  -QueueNames $queueNames `
  -TableNames $tableNames
