#!/bin/bash
set -eux
name="$1"
vol="$2"
force="${3:-noforce}"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

network="${VIRT_INSTALL_NETWORK:-default}"

vmvol="vol-$name"
civol="cidata-$name"

if [[ "$force" == "force" ]]; then
	(virsh dominfo "$name" && virsh destroy "$name" && virsh undefine --nvram "$name") || :
	(virsh vol-info --pool=default "$vmvol" && virsh vol-delete --pool=default "$vmvol") || :
	(virsh vol-info --pool=default "$civol" && virsh vol-delete --pool=default "$civol") || :
else
	virsh dominfo "$name"
	echo "domain $name exists!"
	exit 1
fi

vm-thin-clone-vol "$vol" "$vmvol"

ciiso="$(mktemp -d)/cidata.iso"
vm-mkcidata --address=10.0.10.66/24 "$name" "$ciiso" --username jokamoto --password password
vm-import-vol "$civol" "$ciiso"

virt-install \
	--name "$name" \
	--network "network=$network" \
	--boot hd \
	--console pty \
	--vcpus 1 \
	--memory 4096 \
	--cpu host \
	--machine q35 \
	--nographics \
	--controller type=scsi,model=virtio-scsi \
	--disk vol="default/$vmvol",bus=scsi,boot_order=1 \
	--disk vol="default/$civol",bus=scsi \
	--check path_in_use=off --debug
