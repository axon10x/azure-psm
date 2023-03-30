function CopyData()
{
  $Location = "East US"

  $SubscriptionNameSink = ""
  $StorageAccountNameSink = ""

  $SubscriptionNameSource = ""
  $StorageAccountNameSource = ""

  $ResourceGroupNameDataFactory = ""
  $DataFactoryName = ""

  CopyDataWorker `
    -Location $Location `
    -SubscriptionNameSink $SubscriptionNameSink `
    -StorageAccountNameSink $StorageAccountNameSink `
    -SubscriptionNameSource $SubscriptionNameSource `
    -StorageAccountNameSource $StorageAccountNameSource `
    -ResourceGroupNameDataFactory $ResourceGroupNameDataFactory `
    -DataFactoryName $DataFactoryName
}

function CopyDataWorker()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionNameSink,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountNameSink,
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionNameSource,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountNameSource,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupNameDataFactory,
    [Parameter(Mandatory = $true)]
    [string]
    $DataFactoryName
  )
  # Expire SAS an hour from now in UTC
  $expiry = (Get-Date -AsUTC).AddMinutes(60).ToString("yyyy-MM-ddTHH:mmZ")

  Write-Debug -Debug:$true -Message "Setting subscription to $SubscriptionNameSource"
  az account set -s $SubscriptionNameSource

  Write-Debug -Debug:$true -Message "Getting key for $StorageAccountNameSource"
  $accountKeySource = "$(az storage account keys list --account-name $StorageAccountNameSource -o tsv --query '[0].value')"

  Write-Debug -Debug:$true -Message "Create SAS for $StorageAccountNameSource"
  $sasSource = az storage account generate-sas -o tsv --only-show-errors `
    --account-name $StorageAccountNameSource `
    --expiry $expiry  `
    --services bfqt `
    --resource-types sco `
    --permissions lr `
    --https-only

  Write-Debug -Debug:$true -Message "Setting subscription to $SubscriptionNameSink"
  az account set -s $SubscriptionNameSink

  Write-Debug -Debug:$true -Message "Getting key for $StorageAccountNameSink"
  $accountKeySink = "$(az storage account keys list --account-name $StorageAccountNameSink -o tsv --query '[0].value')"

  Write-Debug -Debug:$true -Message "Create SAS for $StorageAccountNameSink"
  $sasSink = az storage account generate-sas -o tsv --only-show-errors `
    --account-name $StorageAccountNameSink `
    --expiry $expiry  `
    --services bfqt `
    --resource-types sco `
    --permissions acdfilprtuwxy `
    --https-only



  # Blobs
  CopyBlobs `
    -StorageAccountNameSource $StorageAccountNameSource `
    -StorageAccountNameSink $StorageAccountNameSink `
    -SasSource $sasSource `
    -SasSink $sasSink

  # Queues
  CopyQueues `
    -StorageAccountNameSink $StorageAccountNameSink

  # Tables
  CopyTables `
    -Location $Location `
    -StorageAccountNameSource $StorageAccountNameSource `
    -StorageAccountNameSink $StorageAccountNameSink `
    -AccountKeySource $accountKeySource `
    -AccountKeySink $accountKeySink `
    -ResourceGroupNameDataFactory $ResourceGroupNameDataFactory `
    -DataFactoryName $DataFactoryName
}

function CopyBlobs()
{
  [CmdletBinding()]
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
    $SasSource,
    [Parameter(Mandatory = $true)]
    [string]
    $SasSink
  )

  $containers = @("container1", "container2") # Could refactor this to just enumerate all containers in source storage account

  foreach ($container in $containers)
  {
    Write-Debug -Debug:$true -Message "Create container $container"
    az storage container create --account-name $StorageAccountNameSink -n $container --auth-mode login --verbose

    Write-Debug -Debug:$true -Message "azcopy sync for $container"
    azcopy sync "https://$StorageAccountNameSource.blob.core.windows.net/$container/?$SasSource" "https://$StorageAccountNameSink.blob.core.windows.net/$container/?$SasSink"
  }
}

function CopyQueues()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountNameSink
  )

  $queues = @("queue1", "queue2") # Could refactor this to just enumerate all queues in source storage account

  foreach ($queue in $queues)
  {
    Write-Debug -Debug:$true -Message "Create queue $queue"
    az storage queue create --account-name $StorageAccountNameSink -n $queue --auth-mode login --verbose
  }
}

function CopyTables()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountNameSource,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountNameSink,
    [Parameter(Mandatory = $true)]
    [string]
    $AccountKeySource,
    [Parameter(Mandatory = $true)]
    [string]
    $AccountKeySink,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupNameDataFactory,
    [Parameter(Mandatory = $true)]
    [string]
    $DataFactoryName
  )

  # Variables
  $dfLsNameSource = $StorageAccountNameSource
  $dfLsNameSink = $StorageAccountNameSink

  $tables = @("table1", "table2") # Could refactor this to just enumerate all tables in source storage account

  Write-Debug -Debug:$true -Message "Create ADF RG $ResourceGroupNameDataFactory"
  $tags = Get-Tags
  az group create -n $ResourceGroupNameDataFactory -l $Location --tags $tags --verbose

  Write-Debug -Debug:$true -Message "Create ADF $DataFactoryName"
  az datafactory create `
    --location $Location `
    -g $ResourceGroupNameDataFactory `
    --factory-name $DataFactoryName

  Write-Debug -Debug:$true -Message "Create linked service $dfLsNameSource"
  $jsonLsSource = '{"annotations":[],"type":"AzureTableStorage","typeProperties":{"connectionString":"DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=' + $StorageAccountNameSource + ';AccountKey=' + $AccountKeySource + '"}}'
  az datafactory linked-service create `
    -g $ResourceGroupNameDataFactory `
    --factory-name $DataFactoryName `
    --linked-service-name $dfLsNameSource `
    --properties $jsonLsSource

  Write-Debug -Debug:$true -Message "Create linked service $dfLsNameSink"
  $jsonLsSink = '{"annotations":[],"type":"AzureTableStorage","typeProperties":{"connectionString":"DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=' + $StorageAccountNameSink + ';AccountKey=' + $AccountKeySink + '"}}'
  az datafactory linked-service create `
    -g $ResourceGroupNameDataFactory `
    --factory-name $DataFactoryName `
    --linked-service-name $dfLsNameSink `
    --properties $jsonLsSink

  foreach ($table in $tables)
  {
    Write-Debug -Debug:$true -Message "Create table $table"
    az storage table create --account-name $StorageAccountNameSink -n $table --auth-mode login --verbose

    Write-Debug -Debug:$true -Message "Create dataset $dataSetNameSource"
    $dataSetNameSource = $dfLsNameSource + "_" + $table
    $jsonDsSource = '{"linkedServiceName": {"referenceName": "' + $dfLsNameSource + '", "type": "LinkedServiceReference"}, "annotations": [], "type": "AzureTable", "schema": [], "typeProperties": {"tableName": "' + $table + '"}}'
    az datafactory dataset create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --dataset-name $dataSetNameSource `
      --properties $jsonDsSource

    Write-Debug -Debug:$true -Message "Create dataset $dataSetNameSink"
    $dataSetNameSink = $dfLsNameSink + "_" + $table
    $jsonDsSink = '{"linkedServiceName": {"referenceName": "' + $dfLsNameSink + '", "type": "LinkedServiceReference"}, "annotations": [], "type": "AzureTable", "schema": [], "typeProperties": {"tableName": "' + $table + '"}}'
    az datafactory dataset create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --dataset-name $dataSetNameSink `
      --properties $jsonDsSink

    $pipelineName = $table

    Write-Debug -Debug:$true -Message "Create pipeline $pipelineName"
    $jsonPipeline = '{"activities":[{"name":"Copy Data","type":"Copy","dependsOn":[],"policy":{"timeout":"0.12:00:00","retry":0,"retryIntervalInSeconds":30,"secureOutput":false,"secureInput":false},"userProperties":[],"typeProperties":{"source":{"type":"AzureTableSource","azureTableSourceIgnoreTableNotFound":false},"sink":{"type":"AzureTableSink","azureTableInsertType":"merge","azureTablePartitionKeyName":{"value":"PartitionKey","type":"Expression"},"azureTableRowKeyName":{"value":"RowKey","type":"Expression"},"writeBatchSize":10000},"enableStaging":false,"translator":{"type":"TabularTranslator","typeConversion":true,"typeConversionSettings":{"allowDataTruncation":false,"treatBooleanAsNumber":false}}},"inputs":[{"referenceName":"' + $dataSetNameSource + '","type":"DatasetReference"}],"outputs":[{"referenceName":"' + $dataSetNameSink + '","type":"DatasetReference"}]}],"annotations":[]}'
    az datafactory pipeline create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --pipeline-name $pipelineName `
      --pipeline $jsonPipeline

    Write-Debug -Debug:$true -Message "Trigger pipeline $pipelineName"
    az datafactory pipeline create-run `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --pipeline-name $pipelineName
  }
}

function Get-Tags()
{
  [CmdletBinding()]
  param
  (
  )

  # Replace : with - in the timestamp because : breaks ARM template tag parameter
  $timestampTagValue = (Get-Date -AsUTC -format s).Replace(":", "-") + "Z"
  $timestampTag = "timestamp=$timestampTagValue"

  $tagsCli = @($timestampTag)

  return $tagsCli
}