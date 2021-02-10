#!/bin/bash

# Provide at least these values
nsgRuleInbound100Src="PROVIDE" # Leave empty to not add an inbound NSG rule for dev/test - see the net.nsg template
adminUsername="PROVIDE"
# In the form single-line, 'ssh-rsa key== username'
adminPublicKey="PROVIDE"

# Subscription ID. Can be hard-coded (first line), OR can use az account show (second line) to get the default subscription in current authentication context.
# subscriptionId="PROVIDE"
subscriptionId="$(az account show -o tsv --query 'id')"

# Get Tenant ID for Subscription. Need this to create User-Assigned Managed Identity and Key Vault.
tenantId="$(az account show --subscription ""$subscriptionId"" -o tsv --query 'tenantId')"

# Get current user context object ID. Need this to set initial Key Vault Access Policy so secrets etc. can be set/read in these scripts.
userObjectId="$(az ad signed-in-user show -o tsv --query 'objectId')"

# Change this as desired. Suggest making it indicative of the VM OS publisher configured below.
osInfix="rhel"

# Deployment
location1="eastus2"
location2="centralus"

resourceNamingInfix="pz"

# Resource Groups
rgNameSecurityLocation1="vm-security-""$location1"
rgNameSigLocation1="vm-sig-""$location1"
rgNameNetLocation1="vm-net-""$location1"
rgNameSourceLocation1="vm-source-""$location1"
rgNameDeployLocation1="vm-deploy-""$location1"

# User-Assigned Managed Identity
userNameUAMILocation1="$resourceNamingInfix""-vm-uami-""$location1"

# Key Vault
keyVaultSkuName="Standard"
keyVaultNameLocation1="kv-""$resourceNamingInfix""-""$location1"
keyVaultSecretNameAdminUsername="vmAdminUsername"
keyVaultSecretNameAdminSshPublicKey="vmAdminSshPublicKey"

# Network
nsgNameLocation1="vm-test-nsg-""$location1"
vnetNameLocation1="vm-test-vnet-""$location1"
vnetPrefixLocation1="10.4.0.0/16"
vnetPrefixLocation2="10.8.0.0/16"
subnetName="subnet1"
subnetPrefixLocation1="10.4.1.0/24"
subnetPrefixLocation2="10.8.1.0/24"

# ARM Templates
templateUami="../../template/identity.user-assigned-mi.json"
templateKeyVault="../../template/key-vault.json"
templateKeyVaultSecret="../../template/key-vault.secret.json"
templateNsg="../../template/net.nsg.json"
templateVnet="../../template/net.vnet.json"
templateSubnet="../../template/net.vnet.subnet.json"
templatePublicIp="../../template/net.public-ip.json"
templateNetworkInterface="../../template/net.network-interface.json"
templateVirtualMachine="../../template/vm.linux.json"

# VM
hyperVGeneration="V1"
osState="Generalized"

# ##################################################
# FOR CONVENIENCE, TWO VM OS BLOCKS PROVIDED.
# COMMENT ONE OUT.
# VM1 and VM2 are used for source images.
# VM3 is used for OS disk swaps. It is initially deployed with the oldest OS, then VM1 and VM2 are progressively newer versions to swap TO.
# Note that all three OS disks are swappable. So you can start with the VM3 OS disk, swap to VM1, VM2, and back to VM3, or as needed (no specific order is required).
# ##################################################
#vmPublisher="Canonical"
#vmOffer="UbuntuServer"
#vm1Sku="16.04-LTS"
#vm2Sku="18.04-LTS"
#vm3Sku="14.04.5-LTS"
# ##################################################
vmPublisher="RedHat"
vmOffer="RHEL"
vm1Sku="7.8"
vm2Sku="7_9"
vm3Sku="7.7"
# ##################################################

vmVersion="latest"

enableAcceleratedNetworking="true" # This is not supported for all VM Sizes - check your VM Size!
provisionVmAgent="true"
vmSize="Standard_D4s_v3"

vmPublicIpType="Dynamic" # Static or Dynamic - Standard SKU requires Static
vmPublicIpSku="Basic" # Basic or Standard

privateIpAllocationMethod="Dynamic"
ipConfigName="ipConfig1"

vmTimeZoneLocation1="Eastern Standard Time"

osDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
osDiskSizeInGB=64
dataDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
dataDiskCount=0
dataDiskSizeInGB=32
vmAutoShutdownTime="1800"
enableAutoShutdownNotification="Disabled"
autoShutdownNotificationWebhookURL="" # Provide if set enableAutoShutdownNotification="Enabled"
autoShutdownNotificationMinutesBefore=15

# Source VMs
vm1NameLocation1="pz-""$osInfix""-vm1"
vm2NameLocation1="pz-""$osInfix""-vm2"
vm1PipNameLocation1="$vm1NameLocation1""-pip"
vm2PipNameLocation1="$vm2NameLocation1""-pip"
vm1NicNameLocation1="$vm1NameLocation1""-nic"
vm2NicNameLocation1="$vm2NameLocation1""-nic"

# Destination VM
vm3NameLocation1="pz-""$osInfix""-vm3"
vm3PipNameLocation1="$vm3NameLocation1""-pip"
vm3NicNameLocation1="$vm3NameLocation1""-nic"
vm3OsDiskNameVersion0="$vm3NameLocation1""-os-2101"
vm3OsDiskNameVersion1="$vm3NameLocation1""-os-2102"
vm3OsDiskNameVersion2="$vm3NameLocation1""-os-2103"

#SIG
sigName="sig"
osType="Linux"
imageDefinition1="custom-""$osInfix""-v1"
imageVersion1="1.0.0"
imageDefinition2="custom-""$osInfix""-v2"
imageVersion2="1.0.0"

vm1ImageName="$vm1NameLocation1""-image"
vm2ImageName="$vm2NameLocation1""-image"

# New VM admin user in step13
newAdminUsername="newAdmin"
