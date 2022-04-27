# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoVNet()
{
	param
	(
		[string]$DeploymentName,
		[string]$VNetName,
		[string]$VNetAddressSpace,
		[string]$ResourceGroupName,
		[string]$AzureRegion,
		[string]$TemplateFilePath,
		[string]$ParametersFilePath
	)

	$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

	if ($null -eq $vnet){
		Write-Host("Creating VNet " + $VNetName + " in resource group " + $ResourceGroupName + " and region " + $AzureRegion)

		New-AzureRmResourceGroupDeployment `
			-Name ($DeploymentName + "-VNet") `
			-ResourceGroupName $ResourceGroupName `
			-TemplateFile $TemplateFilePath `
			-TemplateParameterFile $ParametersFilePath `
			-location $AzureRegion `
			-vnet_name $VNetName `
			-vnet_address_space $VNetAddressSpace `
			-Verbose `
			-DeploymentDebugLogLevel All

		$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
	}
	else {
		Write-Host("Found/using existing VNet " + $VNetName + " in resource group " + $ResourceGroupName)
	}

	return $vnet
}

if ($g_DeployBastion) {
	DoVNet `
		-DeploymentName $g_DeploymentName `
		-VNetName $g_VNetNameBastion `
		-VNetAddressSpace $g_VNetAddressSpaceBastion `
		-ResourceGroupName $g_ResourceGroupNameNetworkBastion `
		-AzureRegion $g_AzureRegionBastion `
		-TemplateFilePath $g_TemplateFilePathVNet `
		-ParametersFilePath $g_ParametersFilePathVNet
}

if ($g_DeployCluster1) {
	DoVNet `
		-DeploymentName $g_DeploymentName `
		-VNetName $g_VNetNameRegion1 `
		-VNetAddressSpace $g_VNetAddressSpaceRegion1 `
		-ResourceGroupName $g_ResourceGroupNameNetworkRegion1 `
		-AzureRegion $g_AzureRegion1 `
		-TemplateFilePath $g_TemplateFilePathVNet `
		-ParametersFilePath $g_ParametersFilePathVNet
}

if ($g_DeployCluster2) {
	DoVNet `
		-DeploymentName $g_DeploymentName `
		-VNetName $g_VNetNameRegion2 `
		-VNetAddressSpace $g_VNetAddressSpaceRegion2 `
		-ResourceGroupName $g_ResourceGroupNameNetworkRegion2 `
		-AzureRegion $g_AzureRegion2 `
		-TemplateFilePath $g_TemplateFilePathVNet `
		-ParametersFilePath $g_ParametersFilePathVNet
}

if ($g_DeployCluster3) {
	DoVNet `
		-DeploymentName $g_DeploymentName `
		-VNetName $g_VNetNameRegion3 `
		-VNetAddressSpace $g_VNetAddressSpaceRegion3 `
		-ResourceGroupName $g_ResourceGroupNameNetworkRegion3 `
		-AzureRegion $g_AzureRegion3 `
		-TemplateFilePath $g_TemplateFilePathVNet `
		-ParametersFilePath $g_ParametersFilePathVNet
}
