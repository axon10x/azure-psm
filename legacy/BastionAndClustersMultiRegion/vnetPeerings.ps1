# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoVNetPeering()
{
	param
	(
		[string]$DeploymentName,
		[string]$SubscriptionId,
		[string]$ResourceGroupNameLocal,
		[string]$ResourceGroupNameRemote,
		[string]$VNetNameLocal,
		[string]$VNetNameRemote,
		[string]$VNetAddressSpaceRemote,
		[string]$TemplateFilePath,
		[string]$ParametersFilePath
	)

	$peeringName = ($VNetNameLocal + "-" + $VNetNameRemote)

	$peering = Get-AzureRmVirtualNetworkPeering -Name $peeringName -ResourceGroupName $ResourceGroupNameLocal -VirtualNetworkName $VNetNameLocal -ErrorAction SilentlyContinue

	if ($null -eq $peering) {
		Write-Host("Creating VNet Peering " + $peeringName + " in resource group " + $ResourceGroupNameLocal)

		New-AzureRmResourceGroupDeployment `
			-Name ($DeploymentName + "-VNetPeering") `
			-ResourceGroupName $ResourceGroupNameLocal `
			-TemplateFile $TemplateFilePath `
			-TemplateParameterFile $ParametersFilePath `
			-subscription_id $SubscriptionId `
			-vnet_peering_name $peeringName `
			-resource_group_name_remote $ResourceGroupNameRemote `
			-vnet_name_local $VNetNameLocal `
			-vnet_name_remote $VNetNameRemote `
			-vnet_address_space_remote $VNetAddressSpaceRemote `
			-Verbose `
			-DeploymentDebugLogLevel All
		
		$peering = Get-AzureRmVirtualNetworkPeering -Name $peeringName -ResourceGroupName $ResourceGroupNameLocal -VirtualNetworkName $VNetNameLocal -ErrorAction SilentlyContinue
	}
	else {
		Write-Host("Found/using existing VNet Peering " + $peeringName + " in resource group " + $ResourceGroupNameLocal)
	}

	return $peering
}

# Bastion -> Cluster1
if ($g_DeployBastion -and $g_DeployCluster1) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion1 -VNetNameLocal $g_VNetNameBastion -VNetNameRemote $g_VNetNameRegion1 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion1 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Bastion -> Cluster2
if ($g_DeployBastion -and $g_DeployCluster2) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion2 -VNetNameLocal $g_VNetNameBastion -VNetNameRemote $g_VNetNameRegion2 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion2 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Bastion -> Cluster3
if ($g_DeployBastion -and $g_DeployCluster3) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion3 -VNetNameLocal $g_VNetNameBastion -VNetNameRemote $g_VNetNameRegion3 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion3 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster1 -> Bastion
if ($g_DeployCluster1 -and $g_DeployBastion) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion1 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkBastion -VNetNameLocal $g_VNetNameRegion1 -VNetNameRemote $g_VNetNameBastion -VNetAddressSpaceRemote $g_VNetAddressSpaceBastion -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster1 -> Cluster2
if ($g_DeployCluster1 -and $g_DeployCluster2) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion1 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion2 -VNetNameLocal $g_VNetNameRegion1 -VNetNameRemote $g_VNetNameRegion2 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion2 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster1 -> Cluster3
if ($g_DeployCluster1 -and $g_DeployCluster3) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion1 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion3 -VNetNameLocal $g_VNetNameRegion1 -VNetNameRemote $g_VNetNameRegion3 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion3 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster2 -> Bastion
if ($g_DeployCluster2 -and $g_DeployBastion) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion2 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkBastion -VNetNameLocal $g_VNetNameRegion2 -VNetNameRemote $g_VNetNameBastion -VNetAddressSpaceRemote $g_VNetAddressSpaceBastion -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster2 -> Cluster1
if ($g_DeployCluster2 -and $g_DeployCluster1) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion2 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion1 -VNetNameLocal $g_VNetNameRegion2 -VNetNameRemote $g_VNetNameRegion1 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion1 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster2 -> Cluster3
if ($g_DeployCluster2 -and $g_DeployCluster3) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion2 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion3 -VNetNameLocal $g_VNetNameRegion2 -VNetNameRemote $g_VNetNameRegion3 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion3 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster3 -> Bastion
if ($g_DeployCluster3 -and $g_DeployBastion) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion3 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkBastion -VNetNameLocal $g_VNetNameRegion3 -VNetNameRemote $g_VNetNameBastion -VNetAddressSpaceRemote $g_VNetAddressSpaceBastion -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster3 -> Cluster1
if ($g_DeployCluster3 -and $g_DeployCluster1) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion3 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion1 -VNetNameLocal $g_VNetNameRegion3 -VNetNameRemote $g_VNetNameRegion1 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion1 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}

# Cluster3 -> Cluster2
if ($g_DeployCluster3 -and $g_DeployCluster2) {DoVNetPeering -DeploymentName $g_DeploymentName -SubscriptionId $g_SubscriptionId -ResourceGroupNameLocal $g_ResourceGroupNameNetworkRegion3 -ResourceGroupNameRemote $g_ResourceGroupNameNetworkRegion2 -VNetNameLocal $g_VNetNameRegion3 -VNetNameRemote $g_VNetNameRegion2 -VNetAddressSpaceRemote $g_VNetAddressSpaceRegion2 -TemplateFilePath $g_TemplateFilePathVNetPeering -ParametersFilePath $g_ParametersFilePathVNetPeering}
