## Azure Deployment: Azure Virtual Machine (VM) - Non-Destructively Swap OS Disks

---

### Summary

This deployment shows how to create VM OS disk images, and to swap a VM's OS disk without deleting and re-creating the associated Azure resources (VM resource, Network Interface, Public IP, Data Disks).

Why is this useful?

- Periodically create new versions of OS disks with up-to-date patches and other configurations
- Maintain multiple environments for development, testing, etc.
- Create clean baseline OS installs for test suites and swap them without affecting/changing other Azure resources
- Etc.

Ten shell scripts are provided: step0 through step9. Each file has a descriptor between the file name start (step designator) and the file extension (.sh). Each script accomplishes one purpose.

[step0.variables.sh](step0.variables.sh): this file sets all variable values used by all the other shell scripts. It is dot-invoked by all the other scripts, which avoids duplicate variable definitions ("Don't Repeat Yourself").

#### One Time / Initial Setup

These are provided for convenience to create the baseline environment. If you have your own process to deploy these, adjust the variable values in [step0.variables.sh](step0.variables.sh) correspondingly.

[step1.deploy-rgs.sh](step1.deploy-rgs.sh): deploys resource groups used for this deployment.

[step2.deploy-network.sh](step2.deploy-network.sh): deploys network resources - Network Security Group (NSG), Virtual Network (VNet), and Subnet.

[step3.deploy-sig.sh](step3.deploy-sig.sh): deploys a [Shared Image Gallery](https://docs.microsoft.com/azure/virtual-machines/shared-image-galleries). This is where custom VM images need to be stored, as the source to later create OS disk images.

#### Periodic / Image Creation

[step4.deploy-source-vms.sh](step4.deploy-source-vms.sh): deploys two virtual machines, and associated network interfaces and public IP addresses, which will be used to capture OS images. This only needs to be run when new images need to be created, for example as part of a periodic new OS image generation process, or to generate multiple distinct test OS images, etc. The choice of two VMs is arbitrary and can be adjusted to create as many, or as few, source VMs as needed.

[step5.deploy-sig-image-definitions.sh](step5.deploy-sig-image-definitions.sh): deploys two Shared Image Gallery Image Definitions, corresponding to the two source VMs deployed in step 4. These Image Definitions are not, themselves, usable to create VM OS disks.

[step6.capture-vms.sh](step6.capture-vms.sh): stops and captures _generalized_ VMs. **You must generalize the source VM(s) BEFORE running this script!** (Depending on the OS to capture, you may be able to add generalization to this script. See note in the script.) After capturing the source VMs, the script creates VM images, then creates Shared Image Gallery Image Versions from the VM images and associates each Image Version to the corresponding Image Definition created in step 5. *The Shared Image Gallery Image Versions are the source artifact for later OS disk creation.*

[step7.create-os-disks-from-sig-images.sh](step7.create-os-disks-from-sig-images.sh): creates OS disks from Shared Image Gallery Image Versions. The created OS disks can be attached to VMs.

#### As Needed

[step8.deploy-dest-vms.sh](step8.deploy-dest-vms.sh): deploys a VM on which OS disk swap will be done. This is a basic VM deployment and can be customized as needed.

[step9.swap-os-disk.sh](step9.swap-os-disk.sh): Deallocates the VM deployed in step 8 and swaps its OS disk. The script is set for three OS disks: the OS disk deployed with the VM in step 8, whose disk ID is stored in variable `$vm3OsDiskIdVersion0`, and the two OS disks created in step 7, stored in variables `$vm3OsDiskIdVersion1` and `$vm3OsDiskIdVersion2`. You can set any of these three variables to the `az vm update` CLI command's `--os-disk` parameter, in order to swap the corresponding OS disk onto the VM.

### Deployment

Edit [step0.variables.sh](step0.variables.sh) and set values for the variables currently set to `{variable name}="PROVIDE"`.

If you need to deploy the basic infrastructure for the later scripts, run the scripts in "One Time / Initial Setup" in sequential order.

If you are creating source images, run the scripts in "Periodic / Image Creation" in sequential order. _Reminder: don't forget to run VM generalization inside your source VM(s) before running Step 6._
Reference: [Linux](https://docs.microsoft.com/azure/virtual-machines/linux/capture-image#step-1-deprovision-the-vm) [Windows](https://docs.microsoft.com/azure/virtual-machines/windows/capture-image-resource)

To create a VM on which to test OS disk swap, run Step 8.

To swap OS disks, run Step 9 as needed. _Reminder: set the disk ID to use on `az vm update --os-disk` to the correct OS disk ID._

### Data Disks

What if a VM has data disks in addition to an OS disk? Data disks do not need to be detached and re-attached from VMs to swap the OS disk; the step9 script will work.

However, you may still need to take appropriate steps inside the guest OS, when swapping a new OS disk onto a VM where you previously had data disks mounted. For example, you may need to create persistent filesystem mounts for the data disks, in order to access the file systems on the data disks. For details, review the Azure docs for managing Azure disks on [Linux](https://docs.microsoft.com/azure/virtual-machines/linux/tutorial-manage-disks) or [Windows](https://docs.microsoft.com/azure/virtual-machines/windows/tutorial-manage-data-disk).

### NOTE

As with all assets in this repo, usage is at your own risk and is not supported by my employer. See [disclaimer](https://github.com/plzm/azure-deploy/) at the root of this repo.
