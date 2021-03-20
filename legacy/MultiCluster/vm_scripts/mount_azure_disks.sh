#!/bin/bash

# Thanks to Tam Huynh - based on his script to mount Azure disks to a Linux VM

mnt_base="/mnt"

for disk in `lsscsi | grep -v "/dev/sda \|/dev/sdb \|/dev/sr0 " | cut -d "/" -f3`
do
        mkfs -F -t ext4 /dev/$disk

        mkdir -p $mnt_base/$disk

        echo "UUID=`blkid -s UUID /dev/$device | cut -d '"' -f2` $mnt_base/$disk ext4  barrier=0,defaults,discard 0 0" | tee -a /etc/fstab

        echo $disk
done

sudo mount -a

exit 0