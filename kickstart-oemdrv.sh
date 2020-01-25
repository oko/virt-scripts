#!/bin/bash
set -eux
kickstart="$1"
output="$2"
ksd="$(mktemp -d)"
cp "$kickstart" "$ksd/ks.cfg"
genisoimage -v -J -r -V OEMDRV -o "$output" "$ksd/ks.cfg"
