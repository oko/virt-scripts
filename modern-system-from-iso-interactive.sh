#!/bin/bash
set -eux
iso="$1"
hostname="$2"

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
	--check path_in_use=off
