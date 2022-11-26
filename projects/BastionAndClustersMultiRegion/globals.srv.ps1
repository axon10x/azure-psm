# ##################################################
# PROVIDE THESE VALUES

# Azure subscription ID
$global:g_SubscriptionId = ""

# External IP address of your location. You can find this using https://bing.com/search?q=what+is+my+ip+address
# This will be used for two purposes:
# 1. Allow access to the bastion NSG - so that you can SSH to the bastion VM and, from there, work with server VMs and other resources not externally accessible
# 2. Allow access to storage accounts for container creation and script upload. This is required so that Linux VMs can successfully mount Azure storage locations.
$global:g_SourceIpAddressToAllow = ""

# Provide only the bare public key value on one line - no "ssh-rsa" prefix or username suffix. The deployment script handles those pieces.
$global:g_SSHPublicKeyValue = ""

# Storage account names must be globally unique and follow Azure storage account naming rules
$global:g_StorageAccountNameBastion = ""
$global:g_StorageAccountNameRegion1 = ""
$global:g_StorageAccountNameRegion2 = ""
$global:g_StorageAccountNameRegion3 = ""

# ##################################################

# ##################################################
# DEFAULTS PROVIDED BUT EDIT AS NEEDED

# This will be used to name resource groups and other resources for VM clusters (e.g. general servers, Oracle VMs, etc.)
$global:g_ClusterNameRoot = "srv"  # e.g. "srv" for general server VMs, "ora" for Oracle VMs

$global:g_DeploymentName = "MultiRegionBastionAndClusters"

$global:g_DeployBastion = $true
$global:g_DeployCluster1 = $true
$global:g_DeployCluster2 = $true
$global:g_DeployCluster3 = $true

$global:g_AzureRegionBastion = "centralus"
$global:g_AzureRegion1 = "eastus"
$global:g_AzureRegion2 = "centralus"
$global:g_AzureRegion3 = "westus"

$global:g_ClusterName1 = ($g_ClusterNameRoot + "1")
$global:g_ClusterName2 = ($g_ClusterNameRoot + "2")
$global:g_ClusterName3 = ($g_ClusterNameRoot + "3")

$global:g_ResourceGroupNameVMsBastion = ("rg-" + $g_AzureRegionBastion + "-bastion")
$global:g_ResourceGroupNameVMsCluster1 = ("rg-" + $g_AzureRegion1 + "-" + $g_ClusterName1)
$global:g_ResourceGroupNameVMsCluster2 = ("rg-" + $g_AzureRegion2 + "-" + $g_ClusterName2)
$global:g_ResourceGroupNameVMsCluster3 = ("rg-" + $g_AzureRegion3 + "-" + $g_ClusterName3)

$global:g_ResourceGroupNameNetworkBastion = $g_ResourceGroupNameVMsBastion
$global:g_ResourceGroupNameStorageBastion = $g_ResourceGroupNameVMsBastion

# We will put network and storage resources that may be shared by multiple clusters into a separate, shared resource group per region
$global:g_ResourceGroupNameNetworkRegion1 = ("rg-" + $g_AzureRegion1 + "-shared")
$global:g_ResourceGroupNameStorageRegion1 = ("rg-" + $g_AzureRegion1 + "-shared")
$global:g_ResourceGroupNameNetworkRegion2 = ("rg-" + $g_AzureRegion2 + "-shared")
$global:g_ResourceGroupNameStorageRegion2 = ("rg-" + $g_AzureRegion2 + "-shared")
$global:g_ResourceGroupNameNetworkRegion3 = ("rg-" + $g_AzureRegion3 + "-shared")
$global:g_ResourceGroupNameStorageRegion3 = ("rg-" + $g_AzureRegion3 + "-shared")


# General
# SSH Public Key - DO NOT ALTER THE NEXT LINE
$global:g_SSHPublicKey = "ssh-rsa " + $g_SSHPublicKeyValue

# ##################################################
# Network: VNet, Subnets, NSGs - file paths reference artifacts in this deployment so if you're going to change these, move the files accordingly.

# ARM files
$global:g_TemplateFilePathStorageExt = ".\arm_files\storage_ext.template.json"
$global:g_ParametersFilePathStorageExt = ".\arm_files\storage_ext.parameters.json"
$global:g_TemplateFilePathStorageNoExt = ".\arm_files\storage_noext.template.json"
$global:g_ParametersFilePathStorageNoExt = ".\arm_files\storage_noext.parameters.json"

$global:g_TemplateFilePathNSGExt = ".\arm_files\nsg_ext.template.json"
$global:g_ParametersFilePathNSGExt = ".\arm_files\nsg_ext.parameters.json"
$global:g_TemplateFilePathNSGNoExt = ".\arm_files\nsg_noext.template.json"
$global:g_ParametersFilePathNSGNoExt = ".\arm_files\nsg_noext.parameters.json"

$global:g_TemplateFilePathVNet = ".\arm_files\vnet.template.json"
$global:g_ParametersFilePathVNet = ".\arm_files\vnet.parameters.json"

$global:g_TemplateFilePathSubnet = ".\arm_files\subnet.template.json"
$global:g_ParametersFilePathSubnet = ".\arm_files\subnet.parameters.json"

$global:g_TemplateFilePathVNetPeering = ".\arm_files\vnetPeering.template.json"
$global:g_ParametersFilePathVNetPeering = ".\arm_files\vnetPeering.parameters.json"

# Bastion
$global:g_VNetNameBastion = "vnet-bastion"
$global:g_VNetAddressSpaceBastion = "10.100.0.0/16"
$global:g_SubnetNameBastion = "subnet-bastion"
$global:g_SubnetAddressSpaceBastion = "10.100.1.0/24"
$global:g_NSGNameBastion = "nsg-bastion"

# Region 1
# VNet per region
$global:g_VNetNameRegion1 = "vnet-region1"
$global:g_VNetAddressSpaceRegion1 = "10.101.0.0/16"

# Subnet and NSG per cluster
$global:g_SubnetNameRegion1 = ("subnet-region1-" + $g_ClusterName1)
$global:g_SubnetAddressSpaceRegion1 = "10.101.11.0/24"
$global:g_NSGNameRegion1 = ("nsg-region1-" + $g_ClusterName1)

# Region 2
# VNet per region
$global:g_VNetNameRegion2 = "vnet-region2"
$global:g_VNetAddressSpaceRegion2 = "10.102.0.0/16"

# Subnet and NSG per cluster
$global:g_SubnetNameRegion2 = ("subnet-region2-" + $g_ClusterName2)
$global:g_SubnetAddressSpaceRegion2 = "10.102.11.0/24"
$global:g_NSGNameRegion2 = ("nsg-region2-" + $g_ClusterName2)

# Region 3
# VNet per region
$global:g_VNetNameRegion3 = "vnet-region3"
$global:g_VNetAddressSpaceRegion3 = "10.103.0.0/16"

# Subnet and NSG per cluster
$global:g_SubnetNameRegion3 = ("subnet-region3-" + $g_ClusterName3)
$global:g_SubnetAddressSpaceRegion3 = "10.103.11.0/24"
$global:g_NSGNameRegion3 = ("nsg-region3-" + $g_ClusterName3)
# ##################################################

# ##################################################
# Storage
$global:g_TemplateFilePathStorage = ".\arm_files\storage.template.json"
$global:g_ParametersFilePathStorage = ".\arm_files\storage.parameters.json"

$global:g_LinuxMountPoint = "/mnt/azure"
$global:g_AzureStorageContainerName = "vmmountroot"
$global:g_AzureStorageScriptsFolder = "scripts"
$global:g_ShellScriptFileName = "helloworld.sh"
$global:g_ShellScriptToUploadLocalPath = ".\bash_scripts\" + $g_ShellScriptFileName
$global:g_ShellScriptToUploadAzurePath = $g_AzureStorageScriptsFolder + "/" + $g_ShellScriptFileName

$global:g_BlobFuseTempPath = "/mnt/blobfusetmp";
$global:g_BlobFuseConfigPath = "/etc/blobfuse_azureblob.cfg";
# ##################################################

# ##################################################
# VM

# Bastion
$global:g_LinuxDistroBastionVM = "Ubuntu"
$global:g_TemplateFilePathBastionVM = ".\arm_files\vm-bastion.template.json"
$global:g_ParametersFilePathBastionVM = ".\arm_files\vm-bastion.parameters.json"

$global:g_BastionVMSize = "Standard_DS3_v2"
$global:g_BastionVMAvailabilitySetName = "bastion-avset"
$global:g_BastionVMName = ($g_ResourceGroupNameVMsBastion + "-bastionvm1")
$global:g_BastionVMAdminUsername = "bastionadmin"
$global:g_BastionVMSSHKeyData = ConvertTo-SecureString -String ($g_SSHPublicKey + " " + $g_BastionVMAdminUsername) -AsPlainText -Force

# Cluster VMs - for a list of available sizes see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes or use Azure CLI command 'az vm list-sizes' with appropriate arguments.
$global:g_LinuxDistroClusterVM = "Ubuntu"  # Ubuntu or OEL. See storagePrep.ps1.
$global:g_TemplateFilePathClusterVM = ".\arm_files\vm-server.template.json"  # vm-server or vm-oel
$global:g_ParametersFilePathClusterVM = ".\arm_files\vm-server.parameters.json"  # vm-server or vm-oel

$global:g_ClusterVMNameRoot = ($g_ClusterNameRoot + "vm")
$global:g_ClusterVMCount = 3

$global:g_ClusterVMSize = "Standard_E16s_v3"
$global:g_ClusterVMAdminUsername = "serveradmin"
$global:g_ClusterVMSSHKeyData = ConvertTo-SecureString -String ($g_SSHPublicKey + " " + $g_ClusterVMAdminUsername) -AsPlainText -Force

# ##################################################
