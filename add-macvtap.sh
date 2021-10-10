#!/bin/bash
set -eux

iface="$1"
ip link show "$iface"

tf="$(mktemp)"

cat > "$tf" <<-EOF
<network>
  <name>macvtap-$iface</name>
  <forward mode="bridge">
    <interface dev="$iface"/>
  </forward>
</network>
EOF

virsh net-define "$tf"
virsh net-autostart "macvtap-$iface"
virsh net-start "macvtap-$iface"
