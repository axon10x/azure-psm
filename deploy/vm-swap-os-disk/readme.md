## Azure Deployment: Azure Virtual Machine (VM) - Non-Destructively Swap OS Disks

---

### Summary

This deployment shows how to create VM OS disk images, and to swap a VM's OS disk without deleting and re-creating the associated Azure resources (VM resource, Network Interface, Public IP, Data Disks).

Why is this useful?

- Periodically create new versions of OS disks with up-to-date patches and other configurations
- Maintain multiple environments for development, testing, etc.
- Create clean baseline OS installs for test suites and swap them without affecting/changing other Azure resources
- Etc.

Fifteen deployment shell scripts are provided: step00 through step14. Each file has a descriptor between the file name start (step designator) and the file extension (.sh). Each script accomplishes one purpose.

[step00.variables.sh](step00.variables.sh): this file sets all variable values used by all the other shell scripts. It is dot-invoked by all the other scripts, which avoids duplicate variable definitions ("Don't Repeat Yourself").

#### One Time / Initial Setup

These are provided for convenience to create the baseline environment. If you have your own process to deploy these, adjust the variable values in [step00.variables.sh](step00.variables.sh) correspondingly.

[step01.deploy-rgs.sh](step01.deploy-rgs.sh): deploys resource groups used for this deployment.

[step02.deploy-uami.sh](step02.deploy-uami.sh): deploys a User-Assigned Managed Identity (UAMI). Use this to configure the VM in step 09 with a UAMI. To use an existing UAMI you already have, don't run step 02; instead, update step 09 to retrieve your UAMI ID.

[step03.deploy-key-vault.sh](step03.deploy-key-vault.sh): deploys a Key Vault, including an Access Policy to show how to grant access permissions to two different principals: the "current" user, as well as the UAMI created in step02. The current user gets full permissions, and the UAMI only gets "Get" permissions to illustrate different levels of access.

[step04.write-secrets-to-key-vault.sh](step04.write-secrets-to-key-vault.sh): writes secrets to a Key Vault for later use in deployment steps. In this case, the admin username and the associated SSH public key are written to Key Vault. This means that later deployment steps do not need to access SSH key files or pass around sensitive values, but retrieve them as needed from Key Vault.

[step05.deploy-network.sh](step05.deploy-network.sh): deploys network resources - Network Security Group (NSG), Virtual Network (VNet), and Subnet.

[step06.deploy-sig.sh](step06.deploy-sig.sh): deploys a [Shared Image Gallery](https://docs.microsoft.com/azure/virtual-machines/shared-image-galleries). This is where custom VM images need to be stored, as the source to later create OS disk images.

#### Periodic / Image Creation

[step07.deploy-source-vms.sh](step07.deploy-source-vms.sh): deploys two virtual machines, and associated network interfaces and public IP addresses, which will be used to capture OS images. This only needs to be run when new images need to be created, for example as part of a periodic new OS image generation process, or to generate multiple distinct test OS images, etc. The choice of two VMs is arbitrary and can be adjusted to create as many, or as few, source VMs as needed.

[step08.deploy-sig-image-definitions.sh](step08.deploy-sig-image-definitions.sh): deploys two Shared Image Gallery Image Definitions, corresponding to the two source VMs deployed in step 07. These Image Definitions are not, themselves, usable to create VM OS disks.

[step09.capture-vms.sh](step09.capture-vms.sh): stops and captures _generalized_ VMs. **You must generalize the source VM(s) BEFORE running this script!** (Depending on the OS to capture, you may be able to add generalization to this script. See note in the script.) After capturing the source VMs, the script creates VM images, then creates Shared Image Gallery Image Versions from the VM images and associates each Image Version to the corresponding Image Definition created in step 08. *The Shared Image Gallery Image Versions are the source artifact for later OS disk creation.*

[step10.create-os-disks-from-sig-images.sh](step10.create-os-disks-from-sig-images.sh): creates OS disks from Shared Image Gallery Image Versions. The created OS disks can be attached to VMs.

#### As Needed

[step11.deploy-dest-vms.sh](step11.deploy-dest-vms.sh): deploys a VM on which OS disk swap will be done. This is a basic VM deployment and can be customized as needed.

**NOTE** Run _EITHER_ step12.opt1.swap-os-disk-with-arm-template.sh _OR_ step12.opt2.swap-os-disk-with-azure-cli.sh. They do the same thing, but use different approaches. The first uses an ARM template to swap the VM OS disk; the second uses an Azure CLI command to swap the VM OS disk.

[step12.opt1.swap-os-disk-with-arm-template.sh](step12.opt2.swap-os-disk-with-arm-template.sh): Deallocates the VM deployed in step 11 and swaps its OS disk. This script uses the same VM ARM template used in earlier steps to deploy VMs, but in this case an OS disk Azure resource ID is passed with the `osDiskId` parameter so that an OS disk swap occurs.

This approach is for situations where you prefer ARM templates to Azure CLI commands, but note that you must run the VM ARM template with the same parameters you used to deploy the VM originally, so that the VM config is preserved. In step11, the VM is deployed with a user-assigned managed identity and an SSH username and public key, and that has to be repeated here, meaning more complexity just to swap an OS disk.

The script is set for three OS disks: the OS disk deployed with the VM in step 11, whose disk ID is stored in variable `$vm3OsDiskIdVersion0`, and the two OS disks created in step 10, stored in variables `$vm3OsDiskIdVersion1` and `$vm3OsDiskIdVersion2`. You can set any of these three variables to the `osDiskId` parameter on the `az deployment group create` command, in order to swap the corresponding OS disk onto the VM.

[step12.opt2.swap-os-disk-with-azure-cli.sh](step12.opt2.swap-os-disk-with-azure-cli.sh): Deallocates the VM deployed in step 11 and swaps its OS disk. This script uses the Azure CLI command `az vm update` to set a new OS disk on the VM. This approach has the advantage of simplicity, but it may not be suitable if you can only run ARM templates.

The script is set for three OS disks: the OS disk deployed with the VM in step 11, whose disk ID is stored in variable `$vm3OsDiskIdVersion0`, and the two OS disks created in step 10, stored in variables `$vm3OsDiskIdVersion1` and `$vm3OsDiskIdVersion2`. You can set any of these three variables to the `az vm update` CLI command's `--os-disk` parameter, in order to swap the corresponding OS disk onto the VM.

### Deployment

Edit [step00.variables.sh](step00.variables.sh) and set values for the variables currently set to `{variable name}="PROVIDE"`.

If you need to deploy the basic infrastructure for the later scripts, run the scripts in "One Time / Initial Setup" in sequential order.

If you are creating source images, run the scripts in "Periodic / Image Creation" in sequential order. _Reminder: don't forget to run VM generalization inside your source VM(s) before running Step 09._
Reference: [Linux](https://docs.microsoft.com/azure/virtual-machines/linux/capture-image#step-1-deprovision-the-vm) [Windows](https://docs.microsoft.com/azure/virtual-machines/windows/capture-image-resource)

To create a VM on which to test OS disk swap, run Step 11.

To swap OS disks, run Step 12 as needed. _Reminder: set the disk ID to use on `az vm update --os-disk` to the correct OS disk ID._

### Post-Deployment: New Admin User

What if you need to create a new admin user on a VM after swapping to a new OS disk?

**NOTE** Run _EITHER_ step13.opt1.create-admin-user-with-custom-script-extension.sh _OR_ step13.opt2.create-admin-user-with-azure-cli.sh. They do the same thing, but use different approaches.

[step13.opt1.create-admin-user-with-custom-script-extension.sh](step13.opt1.create-admin-user-with-custom-script-extension.sh) uses the Azure Custom Script Extension to run a script on the VM. The script is prepared inline, but the Custom Script Extension also supports retrieving a script file from remote locations like Azure Storage. For this purpose, step13.opt1.create-admin-user-with-custom-script-extension.sh also retrieves the managed identity (if one was configured) and sets it onto the extension deployment, so that files can be retrieved from locations where the managed identity has been granted RBAC access.

[step13.opt2.create-admin-user-with-azure-cli.sh](step13.opt2.create-admin-user-with-azure-cli.sh) uses the [az vm user update](https://docs.microsoft.com/cli/azure/vm/user?view=azure-cli-latest#az_vm_user_update) Azure CLI command, which installs and uses the [VMAccess Extension](https://docs.microsoft.com/azure/virtual-machines/extensions/vmaccess). This extension can be used to perform this task, as well as several other administrative tasks.

The option 2 script, which uses `az vm user update`, is much simpler than option 1, which uses the Custom Script Extension. Both options are provided in case one extension is disallowed in your environment.

### Post-Deployment: Data Disks

What if a VM has data disks in addition to an OS disk? Data disks do not need to be detached and re-attached from VMs to swap the OS disk; the step12 script will still work.

However, you may still need to take appropriate steps inside the guest OS, when swapping a new OS disk onto a VM where you previously had data disks mounted. For example, you may need to create persistent filesystem mounts for the data disks, in order to access the file systems on the data disks. For details, review the Azure docs for managing Azure disks on [Linux](https://docs.microsoft.com/azure/virtual-machines/linux/tutorial-manage-disks#prepare-data-disks) or [Windows](https://docs.microsoft.com/azure/virtual-machines/windows/tutorial-manage-data-disk).

These steps are laid out in [step14.prep-data-disks.sh](step14.prep-data-disks.sh), which covers one-time data disk preparation tasks as well as tasks to perform once whenever a new OS disk is swapped in for the first time.

### Resource Cleanup

To clean up all resources deployed in these scripts, simply run [cleanup.sh](cleanup.sh). __WARNING: this will DELETE the Resource Groups deployed in step01, and ALL resources in those Resource Groups!__

### NOTE

As with all assets in this repo, usage is at your own risk. These assets (scripts, templates, etc.) are not supported by my employer. Please perform your own validation and testing as with any public web open source artifact. See [disclaimer](https://github.com/plzm/azure-deploy) at the root of this repo.
