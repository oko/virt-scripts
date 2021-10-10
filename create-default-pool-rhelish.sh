#!/bin/bash
virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images/
virsh pool-autostart default
virsh pool-start default
