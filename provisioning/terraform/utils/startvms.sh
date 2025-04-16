#!/bin/bash

for vm in $(virsh list --all --name); do
  virsh start $vm
done
