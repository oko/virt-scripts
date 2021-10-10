#!/bin/bash

set -eux

img="$1"
net="$2"

qemu="${QEMU:-"qemu-system-x86_64"}"

rundir="$(mktemp -d)"

qemu-img create -f qcow2 -b "$(realpath "$img")" "$rundir/boot.qcow2"

vmnet="mvtap$(printf '%04d' "$(( RANDOM % 10000 ))")"

sudo ip link add link "$net" name "$vmnet" type macvtap
sudo ip link set "$vmnet" address 52:54:00:12:34:56 up
tapid="$(ip -o link show "$vmnet" | grep -oP '^\d+:' | tr -d :)"
tapdev="/dev/tap$tapid"
sudo chmod 666 "$tapdev"

cidir="$rundir/cidata"
mkdir "$cidir"

cat > "$cidir/network-config" <<-EOF
version: 2
ethernets:
	eth0:
		match:
			mac_address: "52:54:00:12:34:56"
		addresses:
			- 10.0.10.65/255.255.255.0
		gateway4: 10.0.10.1
		dhcp: false
EOF

cat > "$cidir/user-data" <<-EOF
#cloud-config
user: username
password: password
chpasswd: { expire: False }
ssh_pwauth: True
EOF

cat > "$cidir/meta-data" <<-EOF
instance-id: temporary
local-hostname: temporary
EOF

genisoimage -r -J -v -V CIDATA -graft-points -o "$rundir/cidata.iso" /="$cidir"

qpid=""

cleanup() {
	kill "$qpid"
	sudo ip link del "$vmnet"
	rm -rf "$rundir"
}

trap cleanup EXIT

set +e
"$qemu" \
	-nodefaults \
	-nographic \
	-accel kvm \
	-machine q35,accel=kvm \
	-smp sockets=1,cores=2,threads=1 \
	-m 2048 \
	-device virtio-scsi-pci,bus=pcie.0,addr=0x1,id=scsi \
	-drive file="$rundir/boot.qcow2",if=none,id=drive0 \
	-device scsi-hd,bus=scsi.0,channel=0,lun=0,drive=drive0 \
	-drive file="$rundir/cidata.iso",if=none,id=drive1 \
	-device scsi-cd,bus=scsi.0,channel=0,lun=1,drive=drive1 \
	-netdev tap,fd=32,id=net0 \
	-device virtio-net,netdev=net0 \
	-vnc localhost:5959 \
	-chardev socket,id=chr0,path="$rundir/con.sock",server,nowait \
	-device isa-serial,chardev=chr0 32<>"$tapdev" &

#-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd \

qpid=$!

wtime=0
while [[ ! -S "$rundir/con.sock" ]]; do
	sleep 0.2
	wtime="$(( wtime + 1 ))"
	if [[ "$wtime" -gt 10 ]]; then
		echo >&2 "error starting up?"
		exit 1
	fi
done

socat UNIX-CONNECT:"$rundir/con.sock" PTY,link="$rundir/pty",raw,echo=0,wait-slave &

wtime=0
while [[ ! -c "$rundir/pty" ]]; do
	sleep 0.2
	wtime="$(( wtime + 1 ))"
	if [[ "$wtime" -gt 10 ]]; then
		echo >&2 "error starting up?"
		exit 1
	fi
done

screen "$rundir/pty"
