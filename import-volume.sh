#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -eux

src="$1"
dst="$2"

rsrc="$(realpath "$src")"
format="$(qemu-img info "$rsrc" --output=json | jq .format)"
if [[ "$format" == "qcow2" ]]; then
	qemu-img info "$rsrc" --output=json | jq .size
else
	size="$(stat -Lc%s "$rsrc")"
fi
virsh vol-create-as default "$dst" "$size" --format "$format"
virsh vol-upload --pool default "$dst" "$rsrc"
