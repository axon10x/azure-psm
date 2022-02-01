## Azure Deployment: Azure Firewall with Public IPs

---

### Summary

[deploy.sh](deploy.sh) deploys an Azure Firewall with Public IP Addresses (PIPs), as well as the associated infrastructure (Resource Group, Network Security Group, VNet, Subnet).

The Azure Firewall can be configured for the following Azure Availability Zone (AZ) settings (in an Azure Region that supports AZs) by setting the `$firewallAvailabilityZones` value as follows:

- Non-zonal: ""
- All AZs: "1,2,3"
- One AZ (e.g. 1): "1"
- Some AZs (e.g. 1,2 but not 3): "1,2"

The [Azure Firewall documentation](https://docs.microsoft.com/azure/firewall/deploy-availability-zone-powershell#create-a-firewall-with-availability-zones) describes the combination of Azure Firewall AZ configurations and permissible associated PIP AZ configurations. As Azure Firewall can be configured for multiple AZs, whereas PIPs can be configured either for none or exactly one AZ, it's worth reviewing the guidelines.

Firewall AZ | Non-Zonal PIP | AZ1 PIP | AZ2 PIP | AZ3 PIP
---- | :----: | :----: | :----: | :-----:
None | Yes | Yes | Yes | Yes
All (1,2,3) | Yes | No | No | No
1,2 or 2,3 or 1,3 | Yes | No | No | No
1 | Yes | Yes | No | No
2 | Yes | No | Yes | No
1 | Yes | No | No | Yes

### Deployment

Edit [deploy.sh](deploy.sh).

Set `$subscriptionId` to the value for your Azure subscription ID.

Set `$firewallAvailabilityZones` to the AZs for the Azure Firewall. This is a comma-delimited string, so you can leave it blank for a non-zonal deployment, or set it to a value like `"1,2"` or `"1,2,3"`.

The script creates four PIP: a non-zonal PIP, and one PIP in each of the three AZs. The corresponding variables are `$pipNameZrLocation1`, `$pipNameZ1Location1`, `$pipNameZ2Location1`, and `$pipNameZ3Location1`.

Set `$publicIpAddressNames` to a comma-delimited string with the PIP names to configure to the Firewall. For example, to configure a Firewall with all four PIPs, use
`publicIpAddressNames="$pipNameZrLocation1"",""$pipNameZ1Location1"",""$pipNameZ2Location1"",""$pipNameZ3Location1"`

(NOTE: It is fully expected that invalid combinations of an AZ-configured Firewall and various of the PIPs will cause the deployment to _fail_. The intent of this script is to test through the permutations easily to understand which will succeed or fail, per the above table.)

Run `./deploy.sh` from a bash prompt with the current [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) installed.

### NOTE

As with all assets in this repo, usage is at your own risk and is not supported by my employer. See [disclaimer](https://github.com/plzm/azure-deploy/) at the root of this repo.
