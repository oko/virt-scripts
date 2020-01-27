#!/bin/bash
set -eux
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

network="${VIRT_INSTALL_NETWORK:-default}"

location="$1"
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
	--network "network=$network" \
	--console pty \
	--vcpus 1 \
	--memory 4096 \
	--cpu host \
	--machine q35 \
	--nographics \
	--controller type=scsi,model=virtio-scsi \
	--location "$location" \
	--extra-args "inst.geoloc=0 inst.text console=ttyS0 inst.repo=$location rd.debug rd.udev.debug" \
	--disk bus=scsi,size=10,format=qcow2,boot_order=1 \
	--disk bus=scsi,path="$ksiso",device=cdrom,format=raw \
	--check path_in_use=off --debug
