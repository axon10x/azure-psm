# Azure Multi-Subnet Linux Platform Cluster Deployment

## PLEASE NOTE

Summary disclaimer for this entire repo: https://github.com/plzm/azure. By using anything in this repo in any way, you agree to that disclaimer.

## Summary

![Architecture](images/architecture.png?raw=true)

This folder contains Azure deployment artifacts to deploy the cluster environment shown above. The deployment includes:

* Resource group (RG)
  * All resources in this deployment are deployed into the same RG
  * If this is changed to a multi-RG deployment, resource references in the ARM templates will need to be updated accordingly
* Azure Resource Manager (ARM) templates
  * Each resource type has its own standalone template, for modularity and easier recombination/modification
* Shell script to perform the deployment - see deploy.sh
  * The deployment script uses the Azure Command-Line Interface (CLI) to deploy resources using ARM templates and the Azure CLI
  * Deployments are individually tracked at the RG level for easier diagnosis
* Virtual network
* Public and private subnets, as well as dedicated subnets for App Gateway and Load Balancer respectively
  * Public subnet VMs are issued public IP addresses
  * Private subnet VMs only receive private IP addresses; public subnet VMs can be used as bastion or jump box hosts to access private subnet VMs
* Network security group (NSG) for each subnet to restrict traffic
* Storage account for post-deployment scripts, diagnostic logs, and eventual VM storage mounts
  * Access to the storage account is restricted to public and private subnets, plus external allowed IP address(es) specified in the deploy script
* Use of both system-assigned Managed Service Identities (MSIs) as well as user-assigned MSIs
  * Referring to the above diagram - Gate, Search, and Data Virtual Machines (VMs) are configured for system-assigned MSIs, whereas Server VMs are configured with the single user-assigned MSI
  * This is to show both approaches; either may be more appropriate for a given scenario
  * For example, a user-assigned identity may be appropriate for easier tracking and governance of a set of equivalent VMs
  * The deploy script assigns Storage Account Contributor role to both the user-assigned as well as system-assigned MSIs generated during the deployment
* Internal load balancer for Layer 4 communication from an ExpressRoute or VPN client when use of private IP addresses makes sense
  * The load balancer's back end pool includes all Gate VMs
* Linux VMs for four different purposes
  * Gate with public IP addresses: gateway/bastion/access management
  * Server VMs with private IP addresses: general cluster worker nodes
  * Data and Search VMs: dedicated to data storage and search indexing/execution
* VMs are configured with OS as well as two data disks
* Availability Zone (AZ) support:
  * VMs are explicitly deployed into each of the three Azure region AZs
  * Other Azure workloads (e.g. App Gateway) are explicitly deployed with cross-AZ redundancy
* VMs are configured to download and run a shell script from the storage account created in the deployment
  * The shell script is accessed using storage account credentials; this is to avoid publicly exposing the deployment script, and restrict access only to VMs in this deployment
* App Gateway for Layer 7 communication from the public internet
  * The App Gateway's back end pool includes all Gate VMs

## References

- Azure ARM template reference for VMs: https://docs.microsoft.com/azure/templates/microsoft.compute/virtualmachines
- Azure ARM template functions: https://docs.microsoft.com/azure/azure-resource-manager/resource-group-template-functions
- Azure CLI reference: https://docs.microsoft.com/cli/azure/?view=azure-cli-latest
- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM custom extension reference: https://docs.microsoft.com/azure/virtual-machines/extensions/custom-script-linux
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage
- Azure Documentation for information on the other Azure resources deployed: https://docs.microsoft.com/azure

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group to be used with this deployment

## Steps - Get Started

- Download the contents of this folder (or clone the entire repo but work in this folder, MultiCluster)
- Open deploy.sh in a good code editor (or a great one, like Visual Studio Code!)
- Review the variables in the top section of deploy.sh. At a minimum, you MUST provide your own values in replacement of the "PROVIDE" placeholder on several lines of the variables section.
- From a terminal (like VS Code's WSL terminal) log into Azure (Azure CLI command: `az login`)
- Either step through the deploy script or (once you have set variables to sensible values, especially the "PROVIDE" placeholders) you can run `./deploy.sh`
- Please note that this deployment, as provided, will deploy 24 VMs! __YOU ARE RESPONSIBLE__ for managing your costs and shutting down or deleting these VMs as soon as you no longer need them!!!

## FINAL NOTES

This deployment will deploy a lot of resources. As provided, 136!

![Azure resources](images/i02.png?raw=true)

Each resource's deployment is individually tracked at the resource group level for easier diagnosis and tracking.

![Deployment tracking](images/i04.png?raw=true)

You did take care to deallocate or delete all the VMs this deployment creates, didn't you??
