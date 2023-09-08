# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoSubnet()
{
  param
  (
    [string]$DeploymentName,
    [string]$VNetName,
    [string]$ResourceGroupName,
    [string]$AzureRegion,
    [string]$NSGName,
    [string]$SubnetName,
    [string]$SubnetAddressSpace,
    [string]$TemplateFilePath,
    [string]$ParametersFilePath
  )

  $vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

  if ($null -eq $vnet) {
    Write-Host("ERROR! Could not find VNet " + $VNetName + " in resource group " + $ResourceGroupName + "! Exiting without changes.")
    return
  }

  $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue

  if ($null -eq $subnet) {
    Write-Host("Creating subnet " + $SubnetName + " in VNet " + $VNetName)

    New-AzureRmResourceGroupDeployment `
      -Name ($DeploymentName + "-Subnet") `
      -ResourceGroupName $ResourceGroupName `
      -TemplateFile $TemplateFilePath `
      -TemplateParameterFile $ParametersFilePath `
      -location $AzureRegion `
      -vnet_name $VNetName `
      -nsg_name $NSGName `
      -subnet_name $SubnetName `
      -subnet_address_space $SubnetAddressSpace `
      -Verbose `
      -DeploymentDebugLogLevel All
  
    # Refresh VNet so can return up to date subnet object
    $vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
  
    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -ErrorAction Stop
  
    Write-Host('Created subnet ' + $SubnetName + " in VNet " + $VNetName)
  }
  else {
    Write-Host("Found/using existing subnet " + $SubnetName + " in VNet " + $VNetName)
  }

  return $subnet
}

if ($g_DeployBastion) {
  DoSubnet `
    -DeploymentName $g_DeploymentName `
    -VNetName $g_VNetNameBastion `
    -ResourceGroupName $g_ResourceGroupNameNetworkBastion `
    -AzureRegion $g_AzureRegionBastion `
    -NSGName $g_NSGNameBastion `
    -SubnetName $g_SubnetNameBastion `
    -SubnetAddressSpace $g_SubnetAddressSpaceBastion `
    -TemplateFilePath $g_TemplateFilePathSubnet `
    -ParametersFilePath $g_ParametersFilePathSubnet
}

if ($g_DeployCluster1) {
  DoSubnet `
    -DeploymentName $g_DeploymentName `
    -VNetName $g_VNetNameRegion1 `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion1 `
    -AzureRegion $g_AzureRegion1 `
    -NSGName $g_NSGNameRegion1 `
    -SubnetName $g_SubnetNameRegion1 `
    -SubnetAddressSpace $g_SubnetAddressSpaceRegion1 `
    -TemplateFilePath $g_TemplateFilePathSubnet `
    -ParametersFilePath $g_ParametersFilePathSubnet
}

if ($g_DeployCluster2) {
  DoSubnet `
    -DeploymentName $g_DeploymentName `
    -VNetName $g_VNetNameRegion2 `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion2 `
    -AzureRegion $g_AzureRegion2 `
    -NSGName $g_NSGNameRegion2 `
    -SubnetName $g_SubnetNameRegion2 `
    -SubnetAddressSpace $g_SubnetAddressSpaceRegion2 `
    -TemplateFilePath $g_TemplateFilePathSubnet `
    -ParametersFilePath $g_ParametersFilePathSubnet
}

if ($g_DeployCluster3) {
  DoSubnet `
    -DeploymentName $g_DeploymentName `
    -VNetName $g_VNetNameRegion3 `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion3 `
    -AzureRegion $g_AzureRegion3 `
    -NSGName $g_NSGNameRegion3 `
    -SubnetName $g_SubnetNameRegion3 `
    -SubnetAddressSpace $g_SubnetAddressSpaceRegion3 `
    -TemplateFilePath $g_TemplateFilePathSubnet `
    -ParametersFilePath $g_ParametersFilePathSubnet
}
