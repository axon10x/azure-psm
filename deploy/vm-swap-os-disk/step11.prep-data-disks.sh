#!/bin/bash

# ALL OF THIS SHOULD BE RUN -->ON<-- THE DESTINATION VM so you should SSH there

# Do this the FIRST TIME the VM comes up - this prepares the data disk filesystems.
# This is NOT needed more than once in the lifetime of a data disk.
# Partition the two data disks for the first time - this is NOT needed each time OS disks are swapped.
# This assumes you left step0.variables.sh/$dataDiskCount=2 - if you changed that, change this accordingly.
# TODO make this and other blocks below loop with step0.variables.sh/$dataDiskCount iterations
sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs /dev/sdc1
sudo partprobe /dev/sdc1

sudo parted /dev/sdd --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs /dev/sdd1
sudo partprobe /dev/sdd1

# Create some test filesystem things so we can reboot or swap OS disks and check that the data disks behave "as expected".
# This is only needed the first time a data disk is mounted, as these filesystem things will persiste across different OS disk swaps.
sudo mkdir /sdc1/azure_was_here
sudo mkdir /sdd1/azure_was_here
# ##########

# Do this the FIRST time an OS disk is swapped on. That is, the FIRST time EACH new OS disk is swapped on.
# Create mount folders - change these if you like, but adjust accordingly below.
# As above, this assumes you left step0.variables.sh/$dataDiskCount=2. If you changed that, change this accordingly.
sudo mkdir /sdc1
sudo mkdir /sdd1
# ##########


# Do this the FIRST time an OS disk is swapped on. That is, the FIRST time EACH new OS disk is swapped on.
# Mount the data disks in the OS - this is needed the FIRST time a new OS disk is mounted, NOT later times an OS disk is swapped in again
sudo mount /dev/sdc1 /sdc1
sudo mount /dev/sdd1 /sdd1
# ##########


# List mounted drives
df -h | grep -i "sd"

# Do this the FIRST time an OS disk is swapped on. That is, the FIRST time EACH new OS disk is swapped on.
# Add data disks to /etc/fstab so they are remounted after reboot
# Get the disk UUIDs
sudo -i blkid
# Examples - yours will vary
# /dev/sdc1 UUID = UUID="c6a08a65-541d-44ad-b6f9-ad0d3149fac6" TYPE="xfs" PARTLABEL="xfspart" PARTUUID="29409068-feb6-4e81-8d5b-20618256c1c0"
# /dev/sdd1 UUID = UUID="f1a63ed0-d22b-4f75-85f7-e8701a7be9e2" TYPE="xfs" PARTLABEL="xfspart" PARTUUID="345ba8ab-bd02-4df9-8091-db5c31895d57"

# Add lines to /etc/fstab - replace your UUID values below
# Be careful, if you goof up /etc/fstab your VM may go bye bye
sudo nano /etc/fstab
# UUID=c6a08a65-541d-44ad-b6f9-ad0d3149fac6   /sdc1  xfs    defaults,nofail   1  2
# UUID=f1a63ed0-d22b-4f75-85f7-e8701a7be9e2   /sdd1  xfs    defaults,nofail   1  2

# Restart
sudo shutdown -r now

# After reboot, verify disks stay mounted - should see the filesystem things created above
ls /sdc1
ls /sdd1

# Woop woop