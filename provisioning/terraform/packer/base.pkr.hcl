packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "centos9" {
  iso_url           = "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-20240527.0-x86_64-boot.iso"
  iso_checksum      = "md5:c03194e0b3d4692d5bcbc6e5df32c8dc"
  output_directory  = "/mnt/nvme/vms/packer/baseimage"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = "20000M"
  format            = "qcow2"
  accelerator       = "kvm"
  http_directory    = "/src/testlab/provisioning/terraform/packer/"
  ssh_username      = "admin"
  ssh_password      = "testlabs"
  ssh_timeout       = "20m"
  vm_name           = "tdhtest"
  net_device        = "virtio-net"
  net_bridge        = "br0"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  boot_command      = ["<tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/base-ks.cfg<enter><wait>"]
  memory            = 2048
  qemuargs          = [
    ["-cpu", "host"],
    ["-smp", "cores=4"]
  ]
}

build {
  sources = ["source.qemu.centos9"]
}

