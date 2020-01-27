#!/bin/bash
set -eux
vmname="$1"
# assume disk is sda because that's what virt-install does (virsh dumpxml $vmname | grep sda)
virsh snapshot-create-as --domain "$vmname" --name postinstall --disk-only --diskspec sda,snapshot=external
