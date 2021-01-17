## Azure Deployment: Azure Firewall with Public IPs

---

### Summary

[deploy.sh](deploy.sh) deploys an Azure Firewall with Public IP Addresses, as well as the associated infrastructure (Resource Group, Network Security Group, VNet, Subnet).

The Azure Firewall can be configured for the following Azure Availability Zone (AZ) settings (in an Azure Region that supports AZs) by setting the `$firewallAvailabilityZones` value as follows:

- Non-zonal: ""
- All AZs: "1,2,3"
- One AZ (e.g. 1): "1"
- Some AZs (e.g. 1,2 but not 3): "1,2"

The [Azure Firewall documentation](https://docs.microsoft.com/azure/firewall/deploy-availability-zone-powershell#create-a-firewall-with-availability-zones) describes the combination of Azure Firewall AZ configurations and permissible associated Public IP Address AZ configurations. As Azure Firewall can be configured for multiple AZs, whereas Public IPs can be configured either for none or exactly one AZ, it's worth reviewing the guidelines.

Firewall AZ | Non-Zonal Public IP | AZ1 Public IP | AZ2 Public IP | AZ3 Public IP
---- | :----: | :----: | :----: | :-----:
None | Yes | Yes | Yes | Yes
All (1,2,3) | Yes | No | No | No
1,2 or 2,3 or 1,3 | Yes | No | No | No
1 | Yes | Yes | No | No
2 | Yes | No | Yes | No
1 | Yes | No | No | Yes

### Deployment

Edit [deploy.sh](deploy.sh). Minimally, set values for `$subscriptionId`. Adjust any other values desired. Run from any bash prompt with the current [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) installed.

### NOTE

As with all assets in this repo, usage is at your own risk and is not supported by my employer. See [disclaimer](/) at the root of this repo.
