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
  $ResourceGroupNameDataFactory,
  [Parameter(Mandatory = $true)]
  [string]
  $DataFunctionsFilePath,
  [Parameter(Mandatory = $false)]
  [int]
  $DaysOlderThan = 14
)

. $DataFunctionsFilePath

$SubscriptionName = $(az account show -o tsv --query 'name')

Remove-ContainersByNamePrefixAndAge -SubscriptionName $SubscriptionName -StorageAccountName $StorageAccountName -NamePrefix $BackupObjectNamePrefix -DaysOlderThan $DaysOlderThan

Remove-TablesByNamePrefixAndAge -SubscriptionName $SubscriptionName -StorageAccountName $StorageAccountName -NamePrefix $BackupObjectNamePrefix -DaysOlderThan $DaysOlderThan

Remove-DataFactoriesByAge -SubscriptionName $SubscriptionName -ResourceGroupName $ResourceGroupNameDataFactory -DaysOlderThan $DaysOlderThan
