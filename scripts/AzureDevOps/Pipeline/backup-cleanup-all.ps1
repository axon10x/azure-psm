param
(
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountName,
  [Parameter(Mandatory = $false)]
  [string]
  $BackupObjectNamePrefix = "bak",
  [Parameter(Mandatory = $true)]
  [string]
  $DataFunctionsFilePath
)

. $DataFunctionsFilePath

$SubscriptionName = $(az account show -o tsv --query 'name')

DeleteContainersByNamePrefix -SubscriptionName $SubscriptionName -StorageAccountName $StorageAccountName -NamePrefix $BackupObjectNamePrefix

DeleteTablesByNamePrefix -SubscriptionName $SubscriptionName -StorageAccountName $StorageAccountName -NamePrefix $BackupObjectNamePrefix
