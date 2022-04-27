using namespace Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel;

param
(
	[string]$LinuxDistro,
	[string]$ResourceGroupNameStorage,
	[string]$StorageAccountName,
	[string]$StorageContainerName,
	[string]$FileToUploadLocalPath,
	[string]$FileToUploadAzurePath,
	[string]$VMUserName,
	[string]$BlobFuseTempPath,
	[string]$BlobFuseConfigPath,
	[string]$LinuxMountPoint
)

class StoragePrep {
	[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer]DoStorageContainer(
		[Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]$StorageContext,
		[string]$ContainerName
	)
	{
		if ($null -eq $StorageContext) {
			Write-Host("ERROR! Storage context parameter was null! Exiting without changes.")
			return $null
		}

		$container = Get-AzureStorageContainer -Context $StorageContext -Name $ContainerName -ErrorAction SilentlyContinue

		if ($null -eq $container) {
			Write-Host("Creating storage container " + $ContainerName + " in storage account " + $StorageContext.StorageAccountName)

			$container = New-AzureStorageContainer -Context $StorageContext -Name $ContainerName -ClientTimeoutPerRequest 15 -ServerTimeoutPerRequest 15 -Verbose
		}
		else {
			Write-Host("Found/using existing storage container " + $ContainerName + " in storage account " + $StorageContext.StorageAccountName)
		}

		return $container
	}

	[string]GetBlobFuseConfigContent(
		[string]$StorageAccountName,
		[string]$StorageAccountKey,
		[string]$StorageContainerName
	)
	{
		$blobFuseConfigContent = "accountName " + $StorageAccountName + "\n" + "accountKey " + $StorageAccountKey + "\n" + "containerName " + $StorageContainerName

		return $blobFuseConfigContent
	}
	
	[string]GetShellCmd(
			[string]$LinuxDistro,
			[string]$BlobFuseTempPath,
			[string]$UserName,
			[string]$BlobFuseConfigPath,
			[string]$BlobFuseConfigContent,
			[string]$LinuxMountPoint,
			[string]$ShellScriptAzurePath
	)
	{
		$result = $null

		if ($LinuxDistro -eq "Ubuntu")
		{
			# Following lines from blob fuse install wiki currently not working on Ubuntu 18. Below script block using alternate method.
			# "sudo wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && " + `
			# "sudo dpkg -i packages-microsoft-prod.deb && " + `

			# $result = "sudo apt-get update -y;"
			$result = `
				"curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > ./microsoft-prod.list && " + `
				"sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/ && " + `
				"curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && " + `
				"sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/ && " + `
				"sudo mkdir " + $BlobFuseTempPath + " && " + `
				"sudo chown " + $UserName + " " + $BlobFuseTempPath + " && " + `
				"sudo bash -c 'echo -e """ + $BlobFuseConfigContent + """ >> " + $BlobFuseConfigPath + "' && " + `
				"sudo mkdir " + $LinuxMountPoint + " && " + `
				"sudo apt-get update -y && " + `
				"sudo apt-get install -y blobfuse fuse && " + `
				"sudo blobfuse " + $LinuxMountPoint + " --tmp-path=" + $BlobFuseTempPath + " --config-file=" + $BlobFuseConfigPath + " -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
				"sudo bash " + $LinuxMountPoint + "/" + $ShellScriptAzurePath + ";"
		}
		elseif ($LinuxDistro -eq "OEL")
		{
			$result = `
				"sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm && " + `
				"sudo yum clean all && sudo yum update -y --releasever=7.5 && " + `
				"sudo mkdir " + $BlobFuseTempPath + " && " + `
				"sudo chown " + $UserName + " " + $BlobFuseTempPath + " && " + `
				"sudo bash -c 'echo -e """ + $BlobFuseConfigContent + """ >> " + $BlobFuseConfigPath + "' && " + `
				"sudo mkdir " + $LinuxMountPoint + " && " + `
				"sudo yum install -y blobfuse fuse && " + `
				"sudo blobfuse " + $LinuxMountPoint + " --tmp-path=" + $BlobFuseTempPath + " --config-file=" + $BlobFuseConfigPath + "  -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
				"sudo bash " + $LinuxMountPoint + "/" + $ShellScriptAzurePath + ";"
		}
		else
		{
			Write-Host("Linux distro " + $LinuxDistro + " is not supported in this deployment. Please use 'Ubuntu' or 'OEL'.")
		}

		return $result;
	}

	[string]Execute(
		[string]$LinuxDistro,
		[string]$ResourceGroupNameStorage,
		[string]$StorageAccountName,
		[string]$StorageContainerName,
		[string]$FileToUploadLocalPath,
		[string]$FileToUploadAzurePath,
		[string]$VMUserName,
		[string]$BlobFuseTempPath,
		[string]$BlobFuseConfigPath,
		[string]$LinuxMountPoint
	)
	{
		# Get storage account key so we can get storage context
		$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorage -Name $StorageAccountName)[0].Value

		# Get storage context for container and upload operations
		$storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey

		# Ensure the container for Linux VM storage mount exists
		$storageContainer = $this.DoStorageContainer($storageContext, $StorageContainerName)

		# Upload the bash script with overwrite if exists
		$storageBlob = Set-AzureStorageBlobContent -Context $storageContext -Container $StorageContainerName -File $FileToUploadLocalPath -Blob $FileToUploadAzurePath -BlobType Block -Force

		# Get contents of the config file we will write to the VM for Blob Fuse
		$blobFuseConfigContent = $this.GetBlobFuseConfigContent($StorageAccountName, $storageAccountKey, $StorageContainerName)

		$shellCmd = $this.GetShellCmd($LinuxDistro, $BlobFuseTempPath, $VMUserName, $BlobFuseConfigPath, $blobFuseConfigContent, $LinuxMountPoint, $FileToUploadAzurePath)

		return $shellCmd
	}
}

$prep = New-Object -TypeName StoragePrep

$result = $prep.Execute($LinuxDistro, $ResourceGroupNameStorage, $StorageAccountName, $StorageContainerName, $FileToUploadLocalPath, $FileToUploadAzurePath, $VMUserName, $BlobFuseTempPath, $BlobFuseConfigPath, $LinuxMountPoint)

# Optional: write command out to file fo rinspection/debugging
# $result | Out-File "post_deploy_cmd.txt"

return $result
