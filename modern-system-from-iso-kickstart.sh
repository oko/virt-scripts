#!/bin/bash
set -eux
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

iso="$1"
hostname="$2"
kickstart="$3"

ksiso="/var/lib/libvirt/images/$hostname-kickstart.iso"
tmpiso="/tmp/$(basename "$ksiso")"
"$SCRIPTPATH/kickstart-oemdrv.sh" "$kickstart" "$tmpiso"
sudo cp "$tmpiso" "$ksiso"
sudo restorecon "$ksiso"

virt-install \
	--name "$hostname" \
	--boot uefi \
	--qemu-commandline="-boot c" \
	--network default \
	--console pty \
	--vcpus 1 \
	--memory 1024 \
	--cpu host \
	--machine q35 \
	--nographics \
	--controller type=scsi,model=virtio-scsi \
	--disk bus=scsi,size=10,format=qcow2,boot_order=1 \
	--disk bus=scsi,path="$iso",device=cdrom,format=raw,boot_order=2 \
	--disk bus=scsi,path="$ksiso",device=cdrom,format=raw \
	--check path_in_use=off
