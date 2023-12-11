function Copy-StorageData()
{
  [CmdletBinding()]
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
    $DataFactoryName,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $ContainerNamesSource,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $TableNamesSource,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $ContainerNamesSink,
    [Parameter(Mandatory = $false)]
    [string[]]
    [AllowEmptyCollection()]
    $QueueNamesSink,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $TableNamesSink
  )
  # Expire SAS an hour from now in UTC
  $expiry = (Get-Date -AsUTC).AddMinutes(60).ToString("yyyy-MM-ddTHH:mmZ")

  Write-Debug -Debug:$debug -Message "Set subscription to source $SubscriptionNameSource"
  az account set -s $SubscriptionNameSource

  Write-Debug -Debug:$debug -Message "Get key for source account $StorageAccountNameSource"
  $accountKeySource = "$(az storage account keys list --account-name $StorageAccountNameSource -o tsv --query '[0].value')"

  Write-Debug -Debug:$debug -Message "Create SAS for source account $StorageAccountNameSource"
  $sasSource = az storage account generate-sas -o tsv --only-show-errors `
    --account-name $StorageAccountNameSource `
    --account-key $accountKeySource `
    --expiry $expiry  `
    --services bfqt `
    --resource-types sco `
    --permissions lr `
    --https-only

  Write-Debug -Debug:$debug -Message "Set subscription to sink $SubscriptionNameSink"
  az account set -s $SubscriptionNameSink

  Write-Debug -Debug:$debug -Message "Get key for sink $StorageAccountNameSink"
  $accountKeySink = "$(az storage account keys list --account-name $StorageAccountNameSink -o tsv --query '[0].value')"

  Write-Debug -Debug:$debug -Message "Create SAS for sink $StorageAccountNameSink"
  $sasSink = az storage account generate-sas -o tsv --only-show-errors `
    --account-name $StorageAccountNameSink `
    --account-key $accountKeySink `
    --expiry $expiry  `
    --services bfqt `
    --resource-types sco `
    --permissions acdfilprtuwxy `
    --https-only

  # Blobs
  Copy-Blobs `
    -StorageAccountNameSource $StorageAccountNameSource `
    -StorageAccountNameSink $StorageAccountNameSink `
    -SasSource $sasSource `
    -SasSink $sasSink `
    -ContainerNamesSource $ContainerNamesSource `
    -ContainerNamesSink $ContainerNamesSink

  # Queues
  if ($QueueNamesSink -and $QueueNamesSink.Count -gt 0)
  {
    Set-Queues `
      -StorageAccountNameSink $StorageAccountNameSink `
      -SasSink $sasSink `
      -QueueNames $QueueNamesSink
  }

  # Tables
  Copy-Tables `
    -Location $Location `
    -SubscriptionNameDataFactory $SubscriptionNameSource `
    -EnvironmentName $EnvironmentName `
    -StorageAccountNameSource $StorageAccountNameSource `
    -StorageAccountNameSink $StorageAccountNameSink `
    -AccountKeySource $accountKeySource `
    -AccountKeySink $accountKeySink `
    -ResourceGroupNameDataFactory $ResourceGroupNameDataFactory `
    -DataFactoryName $DataFactoryName `
    -TableNamesSource $TableNamesSource `
    -TableNamesSink $TableNamesSink
}

function Copy-Blobs()
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
    $SasSink,
    [Parameter(Mandatory = $true)]
    [string[]]
    $ContainerNamesSource,
    [Parameter(Mandatory = $true)]
    [string[]]
    $ContainerNamesSink
  )

  if (($ContainerNamesSource.Count -eq 0) -or ($ContainerNamesSource.Count -ne $ContainerNamesSink.Count))
  {
    Write-Error "Provide source and sink container names arrays with >0 items and same item counts."
  }
  else
  {
    for ($i = 0; $i -lt $ContainerNamesSource.Count; $i++)
    {
      $containerNameSource = $ContainerNamesSource[$i]
      $containerNameSink = $ContainerNamesSink[$i]

      Write-Debug -Debug:$debug -Message "Create sink container $containerNameSink"
      az storage container create --account-name $StorageAccountNameSink --sas-token $SasSink -n $containerNameSink

      Write-Debug -Debug:$debug -Message "Run azcopy sync from source container $containerNameSource to sink container $containerNameSink"
      azcopy sync "https://$StorageAccountNameSource.blob.core.windows.net/$containerNameSource/?$SasSource" "https://$StorageAccountNameSink.blob.core.windows.net/$containerNameSink/?$SasSink"
    }
  }
}

function Copy-Tables()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionNameDataFactory,
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
    $AccountKeySource,
    [Parameter(Mandatory = $true)]
    [string]
    $AccountKeySink,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupNameDataFactory,
    [Parameter(Mandatory = $true)]
    [string]
    $DataFactoryName,
    [Parameter(Mandatory = $true)]
    [string[]]
    $TableNamesSource,
    [Parameter(Mandatory = $true)]
    [string[]]
    $TableNamesSink
  )

  if (($TableNamesSource.Count -eq 0) -or ($TableNamesSource.Count -ne $TableNamesSink.Count))
  {
    Write-Error "Provide source and sink container names arrays with >0 items and same item counts."
  }
  else
  {
    Write-Debug -Debug:$debug -Message "Setting subscription to $SubscriptionNameDataFactory"
    az account set -s $SubscriptionNameDataFactory

      # Variables
    $dfLsNameSource = $StorageAccountNameSource
    $dfLsNameSink = $StorageAccountNameSink

    Write-Debug -Debug:$debug -Message "Create ADF RG $ResourceGroupNameDataFactory"
    $tags = Get-Tags -EnvironmentName $EnvironmentName
    az group create -n $ResourceGroupNameDataFactory -l $Location --tags $tags

    Write-Debug -Debug:$debug -Message "Create ADF $DataFactoryName"
    az datafactory create `
      --location $Location `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName

    Write-Debug -Debug:$debug -Message "Create linked service $dfLsNameSource"
    $jsonLsSource = '{"annotations":[],"type":"AzureTableStorage","typeProperties":{"connectionString":"DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=' + $StorageAccountNameSource + ';AccountKey=' + $AccountKeySource + '"}}'
    $jsonLsSource > "ls-source.json"
    Write-Debug -Debug:$debug -Message $jsonLsSource

    az datafactory linked-service create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --linked-service-name $dfLsNameSource `
      --properties '@ls-source.json'

    Write-Debug -Debug:$debug -Message "Create linked service $dfLsNameSink"
    $jsonLsSink = '{"annotations":[],"type":"AzureTableStorage","typeProperties":{"connectionString":"DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=' + $StorageAccountNameSink + ';AccountKey=' + $AccountKeySink + '"}}'
    $jsonLsSink > "ls-sink.json"
    Write-Debug -Debug:$debug -Message $jsonLsSink

    az datafactory linked-service create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --linked-service-name $dfLsNameSink `
      --properties '@ls-sink.json'

    for ($i = 0; $i -lt $TableNamesSource.Count; $i++)
    {
      $tableNameSource = $TableNamesSource[$i]
      $tableNameSink = $TableNamesSink[$i]

      Write-Debug -Debug:$debug -Message "Create sink table $tableNameSink"
      az storage table create --account-name $StorageAccountNameSink --account-key $AccountKeySink -n $tableNameSink

      $dataSetNameSource = $dfLsNameSource + "_" + $tableNameSource
      Write-Debug -Debug:$debug -Message "Create dataset $dataSetNameSource"
      $jsonDsSource = '{"linkedServiceName": {"referenceName": "' + $dfLsNameSource + '", "type": "LinkedServiceReference"}, "annotations": [], "type": "AzureTable", "schema": [], "typeProperties": {"tableName": "' + $tableNameSource + '"}}'
      $jsonDsSource > "dataset-source.json"
      Write-Debug -Debug:$debug -Message $jsonDsSource

      az datafactory dataset create `
      -g $ResourceGroupNameDataFactory `
      --factory-name $DataFactoryName `
      --dataset-name $dataSetNameSource `
      --properties '@dataset-source.json'

      $dataSetNameSink = $dfLsNameSink + "_" + $tableNameSink
      Write-Debug -Debug:$debug -Message "Create dataset $dataSetNameSink"
      $jsonDsSink = '{"linkedServiceName": {"referenceName": "' + $dfLsNameSink + '", "type": "LinkedServiceReference"}, "annotations": [], "type": "AzureTable", "schema": [], "typeProperties": {"tableName": "' + $tableNameSink + '"}}'
      $jsonDsSink > "dataset-sink.json"
      Write-Debug -Debug:$debug -Message $jsonDsSink

      az datafactory dataset create `
        -g $ResourceGroupNameDataFactory `
        --factory-name $DataFactoryName `
        --dataset-name $dataSetNameSink `
        --properties '@dataset-sink.json'

      $pipelineName = $tableNameSource + "-" + $tableNameSink

      Write-Debug -Debug:$debug -Message "Create pipeline $pipelineName"
      $jsonPipeline = '{"activities": [{"name": "Copy Data", "type": "Copy", "dependsOn": [], "policy": {"timeout": "0.12:00:00", "retry": 0, "retryIntervalInSeconds": 30, "secureOutput": false, "secureInput": false}, "userProperties": [], "typeProperties": {"source": {"type": "AzureTableSource", "azureTableSourceIgnoreTableNotFound": false}, "sink": {"type": "AzureTableSink", "azureTableInsertType": "merge", "azureTablePartitionKeyName": {"value": "PartitionKey", "type": "Expression"}, "azureTableRowKeyName": {"value": "RowKey", "type": "Expression"}, "writeBatchSize": 10000}, "enableStaging": false, "translator": {"type": "TabularTranslator", "typeConversion": true, "typeConversionSettings": {"allowDataTruncation": false, "treatBooleanAsNumber": false}}}, "inputs": [{"referenceName": "' + $dataSetNameSource + '", "type": "DatasetReference"}], "outputs": [{"referenceName": "' + $dataSetNameSink + '", "type": "DatasetReference"}]}], "annotations": []}'
      $jsonPipeline > "pipeline.json"
      Write-Debug -Debug:$debug -Message $jsonPipeline

      az datafactory pipeline create `
        -g $ResourceGroupNameDataFactory `
        --factory-name $DataFactoryName `
        --pipeline-name $pipelineName `
        --pipeline '@pipeline.json'

      Write-Debug -Debug:$debug -Message "Trigger pipeline $pipelineName"
      az datafactory pipeline create-run `
        -g $ResourceGroupNameDataFactory `
        --factory-name $DataFactoryName `
        --pipeline-name $pipelineName
    }
  }
}

function Set-Queues()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $Sas,
    [Parameter(Mandatory = $true)]
    [string[]]
    [AllowEmptyCollection()]
    $QueueNames
  )

  foreach ($queueName in $QueueNames)
  {
    Write-Debug -Debug:$debug -Message "Create queue $queueName"
    az storage queue create --account-name $StorageAccountName -n $queueName --sas-token $Sas
  }
}

