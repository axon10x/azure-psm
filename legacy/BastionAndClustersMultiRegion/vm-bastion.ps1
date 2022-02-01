# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoVM()
{
	param
	(
		[string]$PostDeployShellCmd
	)

	$vm = Get-AzureRmVM -ResourceGroupName $g_ResourceGroupNameVMsBastion -Name $g_BastionVMName -ErrorAction SilentlyContinue

	if ($null -eq $vm) {
		Write-Host("Creating VM " + $g_BastionVMName + " in resource group " + $g_ResourceGroupNameVMsBastion)

		$deploymentOutput = New-AzureRmResourceGroupDeployment `
			-Name ($g_DeploymentName + "-VM-Bastion") `
			-ResourceGroupName $g_ResourceGroupNameVMsBastion `
			-TemplateFile $g_TemplateFilePathBastionVM `
			-TemplateParameterFile $g_ParametersFilePathBastionVM `
			-location $g_AzureRegionBastion `
			-availability_set_name $g_BastionVMAvailabilitySetName `
			-resource_group_name_vm $g_ResourceGroupNameVMsBastion `
			-virtual_machine_name $g_BastionVMName `
			-virtual_machine_size $g_BastionVMSize `
			-admin_username $g_BastionVMAdminUsername `
			-ssh_key_data $g_BastionVMSSHKeyData `
			-resource_group_name_network $g_ResourceGroupNameNetworkBastion `
			-vnet_name $g_VNetNameBastion `
			-subnet_name $g_SubnetNameBastion `
			-post_deploy_shell_command $PostDeployShellCmd `
			-Verbose `
			-DeploymentDebugLogLevel All
	}
	else {
		Write-Host("Found/using existing VM " + $g_BastionVMName + " in resource group " + $g_ResourceGroupNameVMsBastion + ". No deployment was launched.")
	}

	return $deploymentOutput
}

if ($g_DeployBastion) {
	$postDeployShellCmd = .\storagePrep.ps1 `
		-LinuxDistro $g_LinuxDistroBastionVM `
		-ResourceGroupNameStorage $g_ResourceGroupNameStorageBastion `
		-StorageAccountName $g_StorageAccountNameBastion `
		-StorageContainerName  $g_AzureStorageContainerName `
		-FileToUploadLocalPath $g_ShellScriptToUploadLocalPath `
		-FileToUploadAzurePath $g_ShellScriptToUploadAzurePath `
		-VMUserName $g_BastionVMAdminUsername `
		-BlobFuseTempPath $g_BlobFuseTempPath `
		-BlobFuseConfigPath $g_BlobFuseConfigPath `
		-LinuxMountPoint $g_LinuxMountPoint

	$deploymentOutput = DoVM -PostDeployShellCmd $postDeployShellCmd

	# Uncomment the following lines to see the full deployment output
	# Write-Host "Bastion VM Output";
	# Write-Host $deploymentOutput.OutputsString
	# Write-Host

	$publicFqdnBastionVm = $deploymentOutput.Outputs.publicFqdn.Value

	if ($deploymentOutput.Outputs.publicIpAddressObject.value.publicIPAllocationMethod -eq "Static") {
		$publicIpBastionVm = $deploymentOutput.Outputs.publicIpAddressObject.value.ipAddress.Value
	}
	else {
		$publicIpBastionVm = "Public IP Address is not available at deployment end when dynamic allocation is used."
	}

	Write-Host ("Bastion VM Public FQDN: " + $publicFqdnBastionVm)
	Write-Host ("Bastion VM Public IP Address: " + $publicIpBastionVm)
	Write-Host
}
else {
	Write-Host "Globals set for bastion deployment = false. No actions taken."
}