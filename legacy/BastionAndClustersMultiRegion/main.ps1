# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

# ##################################################
# Login to Azure (interactive) and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $g_SubscriptionId
# ##################################################

# ##################################################
# Ensure resource groups exist
.\resourceGroups.ps1
# ##################################################

# ##################################################
# Networking Resources

# NSGs
.\nsgs.ps1

# VNets
.\vnets.ps1

# Subnets - and associate each subnet to its NSG
.\subnets.ps1

# VNet Peerings
.\vnetPeerings.ps1
# ##################################################

# ##################################################
# Storage accounts for Linux VM mounts
.\storage.ps1;
# ##################################################

# ##################################################
# Deploy Bastion VM
.\vm-bastion.ps1
# ##################################################

# ##################################################
# Deploy VM Clusters
.\vm-cluster.ps1
# ##################################################

