#!/bin/bash

# Provide at least these values
subscriptionId="PROVIDE"
nsgRuleInbound100Src="PROVIDE"
adminUsername="PROVIDE"
adminPublicKey="ssh-rsa PROVIDE== ""$adminUsername"

# Deployment
location1="eastus2"
location2="centralus"

# Resource Groups
rgNameSigLocation1="vm-sig-""$location1"
rgNameNetLocation1="vm-net-""$location1"
rgNameSourceLocation1="vm-source-""$location1"
rgNameDeployLocation1="vm-deploy-""$location1"

# Network
nsgNameLocation1="vm-test-nsg-""$location1"
vnetNameLocation1="vm-test-vnet-""$location1"
vnetPrefixLocation1="10.4.0.0/16"
vnetPrefixLocation2="10.8.0.0/16"
subnetName="subnet1"
subnetPrefixLocation1="10.4.1.0/24"
subnetPrefixLocation2="10.8.1.0/24"

# ARM Templates
templateNsg="../../template/net.nsg.json"
templateVnet="../../template/net.vnet.json"
templateSubnet="../../template/net.vnet.subnet.json"
templatePublicIp="../../template/net.public-ip.json"
templateNetworkInterface="../../template/net.network-interface.json"
templateVirtualMachine="../../template/vm.linux.json"

# VM
hyperVGeneration="V1"
osState="Generalized"

vmPublisher="Canonical"
vmOffer="UbuntuServer"
vmVersion="latest"
vm1Sku="16.04-LTS"
vm2Sku="18.04-LTS"
vm3Sku="14.04.5-LTS"

enableAcceleratedNetworking="true" # This is not supported for all VM Sizes - check your VM Size!
provisionVmAgent="true"
vmSize="Standard_D4s_v3"

vmPublicIpType="Static" # Static or Dynamic - Standard SKU requires Static
vmPublicIpSku="Standard" # Basic or Standard

privateIpAllocationMethod="Dynamic"
ipConfigName="ipConfig1"

vmTimeZoneLocation1="Eastern Standard Time"

osDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
osDiskSizeInGB=32
dataDiskStorageType="Premium_LRS" # Accepted values: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS
dataDiskCount=0
dataDiskSizeInGB=32
vmAutoShutdownTime="1800"
enableAutoShutdownNotification="Disabled"
autoShutdownNotificationWebhookURL="" # Provide if set enableAutoShutdownNotification="Enabled"
autoShutdownNotificationMinutesBefore=15

# Source VMs
vm1NameLocation1="pz-vm1"
vm2NameLocation1="pz-vm2"
vm1PipNameLocation1="$vm1NameLocation1""-pip"
vm2PipNameLocation1="$vm2NameLocation1""-pip"
vm1NicNameLocation1="$vm1NameLocation1""-nic"
vm2NicNameLocation1="$vm2NameLocation1""-nic"

# Destination VM
vm3NameLocation1="pz-vm3"
vm3PipNameLocation1="$vm3NameLocation1""-pip"
vm3NicNameLocation1="$vm3NameLocation1""-nic"
vm3OsDiskNameVersion1="$vm3NameLocation1""-os-""v1-1.0.0"
vm3OsDiskNameVersion2="$vm3NameLocation1""-os-""v2-1.0.0"

#SIG
sigName="sig"
osType="Linux"
imageDefinition1="custom-ubuntu-1604"
imageVersion1="1.0.0"
imageDefinition2="custom-ubuntu-1804"
imageVersion2="1.0.0"

vm1ImageName="$vm1NameLocation1""-image"
vm2ImageName="$vm2NameLocation1""-image"
