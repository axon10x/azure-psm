# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoNSG()
{
  param
  (
    [string]$DeploymentName,
    [string]$ResourceGroupName,
    [string]$AzureRegion,
    [string]$NSGName,
    [string]$ExternalSourceIp = $null,
    [string]$DestinationAddressSpace = $null,
    [string]$TemplateFilePath,
    [string]$ParametersFilePath
  )

  $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName -ErrorAction SilentlyContinue

  if ($null -eq $nsg) {
    Write-Host("Creating NSG " + $NSGName + " in resource group " + $ResourceGroupName)

    if ($ExternalSourceIp -and $DestinationAddressSpace) {
      New-AzureRmResourceGroupDeployment `
        -Name ($DeploymentName + "-NSG") `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFilePath `
        -TemplateParameterFile $ParametersFilePath `
        -location $AzureRegion `
        -nsg_name $NSGName `
        -external_source_ip $ExternalSourceIp `
        -destination_address_space $DestinationAddressSpace `
        -Verbose `
        -DeploymentDebugLogLevel All
    }
    else {
      New-AzureRmResourceGroupDeployment `
        -Name ($DeploymentName + "-NSG") `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFilePath `
        -TemplateParameterFile $ParametersFilePath `
        -location $AzureRegion `
        -nsg_name $NSGName `
        -Verbose `
        -DeploymentDebugLogLevel All
    }

    $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName -ErrorAction SilentlyContinue
  }
  else {
    Write-Host("Found/using existing NSG " + $NSGName + " in resource group " + $ResourceGroupName)
  }

  return $nsg
}

# NSGs - assumption is one NSG per subnet
if ($g_DeployBastion) {
  DoNSG `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupName $g_ResourceGroupNameNetworkBastion `
    -AzureRegion $g_AzureRegionBastion `
    -NSGName $g_NSGNameBastion `
    -ExternalSourceIp $g_SourceIpAddressToAllow `
    -DestinationAddressSpace $g_SubnetAddressSpaceBastion `
    -TemplateFilePath $g_TemplateFilePathNSGExt `
    -ParametersFilePath $g_ParametersFilePathNSGExt
}


if ($g_DeployCluster1) {
  DoNSG `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion1 `
    -AzureRegion $g_AzureRegion1 `
    -NSGName $g_NSGNameRegion1 `
    -TemplateFilePath $g_TemplateFilePathNSGNoExt `
    -ParametersFilePath $g_ParametersFilePathNSGNoExt
}

if ($g_DeployCluster2) {
  DoNSG `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion2 `
    -AzureRegion $g_AzureRegion2 `
    -NSGName $g_NSGNameRegion2 `
    -TemplateFilePath $g_TemplateFilePathNSGNoExt `
    -ParametersFilePath $g_ParametersFilePathNSGNoExt
}

if ($g_DeployCluster3) {
  DoNSG `
    -DeploymentName $g_DeploymentName `
    -ResourceGroupName $g_ResourceGroupNameNetworkRegion3 `
    -AzureRegion $g_AzureRegion3 `
    -NSGName $g_NSGNameRegion3 `
    -TemplateFilePath $g_TemplateFilePathNSGNoExt `
    -ParametersFilePath $g_ParametersFilePathNSGNoExt
}
