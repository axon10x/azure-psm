param
(
  [Parameter(Mandatory = $true)]
  [string]
  $Location,
  [Parameter(Mandatory = $true)]
  [string]
  $EnvironmentName,
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountNameSource,
  [Parameter(Mandatory = $true)]
  [string]
  $StorageAccountNameSink,
  [Parameter(Mandatory = $true)]
  [string]
  $ResourceGroupNameDataFactory,
  [Parameter(Mandatory = $true)]
  [string]
  $DataFactoryName,
  [Parameter(Mandatory = $false)]
  [string]
  $BackupObjectNamePrefix = "bak",
  [Parameter(Mandatory = $true)]
  [string]
  $DataFunctionsFilePath
)

. $DataFunctionsFilePath

$SubscriptionName = $(az account show -o tsv --query 'name')

$timeStamp = Get-TimestampForObjectNaming
Write-Debug -Debug:$true -Message "$timeStamp"

$dataFactoryNameForThisBackup = $DataFactoryName + "-" + $timeStamp

$containerQuery = "[?!(starts_with(name, 'bak') || starts_with(name, 'azure-webjobs') || starts_with(name, 'insights'))].name"
$containerNamesSource = $(az storage container list --account-name $StorageAccountNameSource --auth-mode login -o tsv --query $containerQuery)
$tableQuery = "[?!(name == 'SchemasTable' || starts_with(name, 'bak'))].name"
$tableNamesSource = $(az storage table list --account-name $StorageAccountNameSource --auth-mode login -o tsv --query $tableQuery)

$containerNamesSink = $containerNamesSource | ForEach-Object {$BackupObjectNamePrefix + "-" + $timeStamp + "-" + $_}
$queueNamesSink = @()
$tableNamesSink = $tableNamesSource | ForEach-Object {$BackupObjectNamePrefix + $timeStamp + $_}

Copy-Data `
  -Location $Location `
  -EnvironmentName $EnvironmentName `
  -SubscriptionNameSink $SubscriptionName `
  -StorageAccountNameSink $StorageAccountNameSink `
  -SubscriptionNameSource $SubscriptionName `
  -StorageAccountNameSource $StorageAccountNameSource `
  -ResourceGroupNameDataFactory $ResourceGroupNameDataFactory `
  -DataFactoryName $dataFactoryNameForThisBackup `
  -ContainerNamesSource $containerNamesSource `
  -TableNamesSource $tableNamesSource `
  -ContainerNamesSink $containerNamesSink `
  -QueueNamesSink $queueNamesSink `
  -TableNamesSink $tableNamesSink
