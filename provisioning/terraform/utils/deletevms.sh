#!/bin/bash

# List all VMs
vms=$(virsh list --all --name)

# Loop through each VM
for vm in $vms; do
  # Check if VM exists
  if [ -n "$vm" ]; then
    echo "Shutting down VM: $vm"
    virsh shutdown $vm

    # Wait for the VM to shut down
    while [[ $(virsh domstate $vm) != "shut off" ]]; do
      sleep 1
    done

    echo "Undefining VM: $vm"
    virsh undefine $vm --remove-all-storage

    echo "VM $vm has been deleted."
  fi
done

echo "All VMs have been deleted."
