# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoVM() {
	param
	(
		[string]$ResourceGroupNameVM,
		[string]$AzureRegion,
		[string]$AvailabilitySetName,
		[string]$VMName,
		[string]$ResourceGroupNameNetwork,
		[string]$VNetName,
		[string]$SubnetName,
		[string]$PostDeployShellCmd
	)

	$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupNameVM -Name $VMName -ErrorAction SilentlyContinue

	if ($null -eq $vm) {
		Write-Host("Creating VM " + $VMName + " in resource group " + $ResourceGroupNameVM)

		$deploymentOutput = New-AzureRmResourceGroupDeployment `
			-Name ($g_DeploymentName + "-VM-Cluster") `
			-ResourceGroupName $ResourceGroupNameVM `
			-TemplateFile $g_TemplateFilePathClusterVM `
			-TemplateParameterFile $g_ParametersFilePathClusterVM `
			-location $AzureRegion `
			-availability_set_name $AvailabilitySetName `
			-virtual_machine_name $VMName `
			-virtual_machine_size $g_ClusterVMSize `
			-admin_username $g_ClusterVMAdminUsername `
			-ssh_key_data $g_ClusterVMSSHKeyData `
			-resource_group_name_network $ResourceGroupNameNetwork `
			-vnet_name $VNetName `
			-subnet_name $SubnetName `
			-post_deploy_shell_command $PostDeployShellCmd `
			-Verbose `
			-DeploymentDebugLogLevel All
	}
	else {
		Write-Host("Found/using existing VM " + $VMName + " in resource group " + $ResourceGroupNameVM + ". No deployment was launched.")
	}

	return $deploymentOutput
}

function DoCluster() {
	param
	(
		[string]$ClusterName,
		[string]$AzureRegion,
		[string]$ResourceGroupNameVMs,
		[string]$ResourceGroupNameStorage,
		[string]$StorageAccountName,
		[string]$ResourceGroupNameNetwork,
		[string]$VNetName,
		[string]$SubnetName
	)

	Write-Host ("Deploying cluster " + $ClusterName)

	$postDeployShellCmd = .\storagePrep.ps1 `
		-LinuxDistro $g_LinuxDistroClusterVM `
		-ResourceGroupNameStorage $ResourceGroupNameStorage `
		-StorageAccountName $StorageAccountName `
		-StorageContainerName  $g_AzureStorageContainerName `
		-FileToUploadLocalPath $g_ShellScriptToUploadLocalPath `
		-FileToUploadAzurePath $g_ShellScriptToUploadAzurePath `
		-VMUserName $g_ClusterVMAdminUsername `
		-BlobFuseTempPath $g_BlobFuseTempPath `
		-BlobFuseConfigPath $g_BlobFuseConfigPath `
		-LinuxMountPoint $g_LinuxMountPoint

	for ($i = 1; $i -le $g_ClusterVMCount; $i++) {
		Write-Host ("Deploying " + $ClusterName + " VM" + $i)

		$outputVM = DoVM `
			-ResourceGroupNameVM $ResourceGroupNameVMs `
			-AzureRegion $AzureRegion `
			-AvailabilitySetName ($ClusterName + "-avset") `
			-VMName ($ResourceGroupNameVMs + "-" + $g_ClusterVMNameRoot + $i) `
			-VMSSHKeyData $g_ClusterVMSSHKeyData `
			-ResourceGroupNameNetwork $ResourceGroupNameNetwork `
			-VNetName $VNetName `
			-SubnetName $SubnetName `
			-PostDeployShellCmd $postDeployShellCmd

		$privateIp = $outputVM.Outputs.privateIpAddress.Value
		$privateFqdn = $outputVM.Outputs.privateFqdn.Value

		Write-Host ($ClusterName + " VM" + $i + " Private FQDN: " + $privateIp)
		Write-Host ($ClusterName + " VM" + $i + " Private IP Address: " + $privateFqdn)
		Write-Host
	}
}

if ($g_DeployCluster1) {
	DoCluster `
		-ClusterName $g_ClusterName1 `
		-AzureRegion $g_AzureRegion1 `
		-ResourceGroupNameVMs $g_ResourceGroupNameVMsCluster1 `
		-ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion1 `
		-StorageAccountName $g_StorageAccountNameRegion1 `
		-ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion1 `
		-VNetName $g_VNetNameRegion1 `
		-SubnetName $g_SubnetNameRegion1
}

if ($g_DeployCluster2) {
	DoCluster `
		-ClusterName $g_ClusterName2 `
		-AzureRegion $g_AzureRegion2 `
		-ResourceGroupNameVMs $g_ResourceGroupNameVMsCluster2 `
		-ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion2 `
		-StorageAccountName $g_StorageAccountNameRegion2 `
		-ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion2 `
		-VNetName $g_VNetNameRegion2 `
		-SubnetName $g_SubnetNameRegion2
}

if ($g_DeployCluster3) {
	DoCluster `
		-ClusterName $g_ClusterName3 `
		-AzureRegion $g_AzureRegion3 `
		-ResourceGroupNameVMs $g_ResourceGroupNameVMsCluster3 `
		-ResourceGroupNameStorage $g_ResourceGroupNameStorageRegion3 `
		-StorageAccountName $g_StorageAccountNameRegion3 `
		-ResourceGroupNameNetwork $g_ResourceGroupNameNetworkRegion3 `
		-VNetName $g_VNetNameRegion3 `
		-SubnetName $g_SubnetNameRegion3
}

