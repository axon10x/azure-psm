# Azure Multi-Region Linux Environment Deployment

## PLEASE NOTE

Summary disclaimer for this entire repo: https://github.com/plzm/azure. By using anything in this repo in any way, you agree to that disclaimer.

## Summary

This folder contains scripts and templates to deploy a multi-region environment that includes:

- Resource groups (RGs) for bastion resources, and per cluster region, a resource group for shared resources and a cluster RG. If you deploy both general server (srv) and Oracle Enterprise Linux (OEL) clusters (ora), then you will have three RGs per region: a shared resources RG, a general cluster RG, and an Oracle cluster RG.
- In each region's shared RG, networking resources including a Network Security Group (NSG) per cluster, a Virtual Network (VNet), and a subnet per cluster in the VNet. Each subnet is associated to, and protected by, the corresponding NSG.
- VNets are peered in all possible combinations. This is so that any VM can communicate with any other, since the server clusters in each region are assumed to need to communicate with each other and of course with the bastion.
- In each resource group, a storage account with a blob container. This is used as a filesystem mount location in the VMs.
- Storage accounts are protected by encryption at rest and in transit (insecure connections will be refused). Additionally, each storage account is set with firewall rules that deny all network access except from the subnets in the VNet in the same region plus the external IP address you specify in globals.*.ps1.
  - Note that all storage accounts allow access to the external IP address you specify because this deployment creates artifacts (a container and a shell script) in each storage account for use by the VMs. Without this container and shell script, VM deployment will error during post-deploy shell script execution as the deployment will be unable to find the specified container and shell script.
- Virtual machines (VMs):
  - In the bastion RG, a bastion VM with a public IP address. You should SSH to this VM and work with cluster VMs and other protected resources from here.
  - In the cluster RGs, a set of VMs with private IP addresses only.
  - All VMs have a filesystem location mounted to the Azure storage container created in that RG's region (i.e. no cross-region storage traffic from VMs)
  - All VMs use the Azure Blob Fuse driver to mount Azure storage locations. An Azure storage container is mounted and a basic shell script there is run. All of this is installed/configured/executed as part of this deployment. You can edit the shell script for your own purposes; this deployment shows how to automatically run a shell script from Azure storage.

All VM sets use Azure Availability Sets for in-region high availability. Availability Zones are not used, as those are not yet available in every Azure region used by this deployment.

The main controller script is main.ps1. As you'll see, each components (e.g. VNets, storage) runs in its own script so that you can run only what you need. All settings (e.g. resource names) are set in one file: globals.ps1. Edit that file to control your deployment; edit any other file to change the deployment overall.

Components are separated even where they could have been combined in an ARM template. For example, network components are deployed in separate stages: NSGs, VNets, subnets, VNet peerings. Where appropriate, they are separately combined. This modularization / loose coupling is so that other deployments can take place into this deployment's infrastructure with minimal risk of disruption to existing resources, due to idempotency, name overlap, or other reasons (see below remarks).

All scripts include the following:

- Use of Azure Resource Manager (ARM) templates and parameter files
- Use of Powershell to prepare various deployment aspects and to invoke ARM templates and parameter files
- If you are not comfortable with Powershell, this deployment can be rewritten in another language (e.g. shell script) and the ARM templates and parameter files invoked from there
- Idempotency:
- ARM templates are in incremental mode by default, meaning that an already-deployed resource will not be torn down and re-deployed _unless_ the template (and therefore the state of the resource in question) has been changed - be careful.
- Powershell scripts perform existence checks before running ARM templates. Existence checks are as minimal as possible: for example, VMs are checked for by exact name and resource group, and no other aspect is considered when deciding whether to (re)deploy the resource. This is to protect previously deployed resources that may have been deliberately and correctly modified since deployment.
  - __The consequence of this is that you can run this entire script multiple times. Existing resources will not be affected on later runs. ->Idempotency__

This deployment can target both Ubuntu Server 18.10 as well as Oracle Enterprise Linux (OEL) 7.5. Note that for technical reasons, OEL 7.4 images are used, but the post-deploy shell script (in storagePrep.ps1) for OEL then upgrades the VM to OEL 7.5.

![Network Schematic](images/MultiRegionLayout-Network.png?raw=true)

![Infrastructure Schematic](images/MultiRegionLayout-Infrastructure.png?raw=true)

## References

- Azure ARM template Reference for VMs: https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines

- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage

- Azure Blob Fuse Driver
    - https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
    - https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group(s) to be used with this deployment
3. A Powershell execution environment. I recommend Microsoft Visual Studio Code with at minimum the following extensions: Azure Account, Azure CLI Tools, Azure Resource Manager Tools, Azure Storage, JSON Tools, Powershell. You will also need the Azure Powershell install, which you can get at https://azure.microsoft.com/downloads/.

## Steps - Get Started

The idea with this deployment is that the defaults are such that, by just following the few steps below, you will be able to deploy the entire infrastructure shown on the two images linked above, found in the images/ folder. I suggest you edit minimally (see below steps) for at least a first run-through.

- Clone this repo. (Or fork it, if you'd consider improving this artifact and contributing back with Pull Requests!)
- Open the root folder of this repo in Visual Studio Code (VS Code) or another Powershell IDE with debug/step-through capability. I recommend VS Code.
- Edit globals.ps1. As you can see, you will need to uncomment one of the two actual global config files provided with this repo (or create your own similar one and call it here in globals.ps1.) Most of the other .ps1 scripts call globals.ps1, so in globals.ps1 is the one place you need to point at an actual global config file with details about your deployment.
- Edit the actual global config file (i.e. either globals.srv.ps1 or globals.ora.ps1). Provide the mandatory info at the top of the file, and edit the defaults below as needed. I suggest leaving the defaults as is for your first run through a deployment.
    - Note that I use global Powershell variables so that the various .ps1 files can see the values. Due to this, you should not mingle other Powershell work into your Powershell session while working on this deployment. I have not been able to get a lesser variable scope (e.g. Script or Local) to correctly share variables among multiple .ps1 scripts. The trade-off is that this deployment is highly modular, for easier mixing/matching/customization.
  - Use short Azure region names where location is needed. Example: centralus, eastus, westus, etc. (see https://azure.microsoft.com/regions/ or use CLI command:\
```az account list-locations -o table```
- Step through main.ps1.
