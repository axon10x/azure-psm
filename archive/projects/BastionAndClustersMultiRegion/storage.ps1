# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoStorage()
{
  param
  (
    [string]$DeploymentName,
    [string]$ResourceGroupNameStorage,
    [string]$AzureRegion,
    [string]$StorageAccountName,
    [string]$ResourceGroupNameNetwork,
    [string]$VNetName,
    [string]$SubnetName,
    [string]$ExternalSourceIp,
    [string]$TemplateFilePath,
    [string]$ParametersFilePath
  )

  $sa = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupNameStorage -ErrorAction SilentlyContinue

  if ($null -eq $sa){
    Write-Host("Creating storage account " + $StorageAccountName + " in resource group " + $ResourceGroupNameStorage)

    New-AzureRmResourceGroupDeployment `
      -Name ($DeploymentName + "-Storage") `
      -ResourceGroupName $ResourceGroupNameStorage `
      -TemplateFile $TemplateFilePath `
      -TemplateParameterFile $ParametersFilePath `
      -location $AzureRegion `
      -storage_account_name $StorageAccountName `
      -external_source_ip $ExternalSourceIp `
      -Verbose `
      -DeploymentDebugLogLevel All

    $sa = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupNameStorage -ErrorAction SilentlyContinue
  }
  else {
    Write-Host("Found/using existing storage account " + $StorageAccountName + " in resource group " + $ResourceGroupNameStorage)
  }

  # Add network access rules for the subnet in question to the storage account
  # We do this outside the existence check above, since even for an already-created storage account, we may have a new subnet in the VNet that now needs access to the shared storage account.
  # We use SilentlyContinue below in case the rule already exists, in which case the cmdlet by default will issue an error message.
  $vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupNameNetwork
  $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
  Add-AzureRMStorageAccountNetworkRule -ResourceGroupName $ResourceGroupNameNetwork -Name $StorageAccountName -VirtualNetworkResourceId $subnet.Id -Verbose -ErrorAction SilentlyContinue

  return $sa
}

# Bastion
if ($g_DeployBastion) {
  DoStorage `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupNameStorage $g_ResourceGroupNameStorageBastion `
    -AzureRegion $g_AzureRegionBastion `
    -StorageAccountName $g_StorageAccountNameBastion `
    -ResourceGroupNameNetwork $g_ResourceGroupNameNetworkBastion `
    -VNetName $g_VNetNameBastion `
    -SubnetName $g_SubnetNameBastion `
    -ExternalSourceIp $g_SourceIpAddressToAllow `
    -TemplateFilePath $g_TemplateFilePathStorageExt `
    -ParametersFilePath $g_ParametersFilePathStorageExt
}

# Cluster1
if ($g_DeployCluster1) {
  DoStorage `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion1 `
    -AzureRegion $g_AzureRegion1 `
    -StorageAccountName $g_StorageAccountNameRegion1 `
    -ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion1 `
    -VNetName $g_VNetNameRegion1 `
    -SubnetName $g_SubnetNameRegion1 `
    -ExternalSourceIp $g_SourceIpAddressToAllow `
    -TemplateFilePath $g_TemplateFilePathStorageExt `
    -ParametersFilePath $g_ParametersFilePathStorageExt
}

# Cluster2
if ($g_DeployCluster2) {
  DoStorage `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion2 `
    -AzureRegion $g_AzureRegion2 `
    -StorageAccountName $g_StorageAccountNameRegion2 `
    -ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion2 `
    -VNetName $g_VNetNameRegion2 `
    -SubnetName $g_SubnetNameRegion2 `
    -ExternalSourceIp $g_SourceIpAddressToAllow `
    -TemplateFilePath $g_TemplateFilePathStorageExt `
    -ParametersFilePath $g_ParametersFilePathStorageExt
}

# Cluster3
if ($g_DeployCluster3) {
  DoStorage `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion3 `
    -AzureRegion $g_AzureRegion3 `
    -StorageAccountName $g_StorageAccountNameRegion3 `
    -ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion3 `
    -VNetName $g_VNetNameRegion3 `
    -SubnetName $g_SubnetNameRegion3 `
    -ExternalSourceIp $g_SourceIpAddressToAllow `
    -TemplateFilePath $g_TemplateFilePathStorageExt `
    -ParametersFilePath $g_ParametersFilePathStorageExt
}