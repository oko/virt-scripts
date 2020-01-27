#!/bin/bash
set -eux
iso="$1"
dest="/var/lib/libvirt/images/$(basename "$iso")"
sudo cp "$iso" "$dest"
sudo restorecon "dest"
