#########################################################
##### CentOS Base Image
#########################################################

resource "libvirt_volume" "centos9_image_freeipa" {
  name   = "CentOS-Stream-9-x86_64-${var.domain_name}_freeipa.qcow2"
  pool   = "default"
  source = var.centos9_image_source_path
  format = "qcow2"
}

#########################################################
##### CentOS Virtual Machine
#########################################################

resource "libvirt_domain" "centos9_freeipa" {
  count = var.freeipa_deploy_machine ? 1 : 0

  name   = "freeipa.${var.domain_name}"
  memory = var.freeipa_memory_size
  vcpu   = var.freeipa_cpu_count

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.centos9_image_freeipa.id
  }

  disk {
    volume_id = libvirt_volume.cloud_init_iso_freeipa.id
  }

  network_interface {
    network_name = var.private_network
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    listen_address = "0.0.0.0"
    autoport    = true
  }

  depends_on = [
    local_file.user_data_freeipa,
    local_file.meta_data_freeipa
  ]

  provisioner "local-exec" {
    command = format("virsh autostart %s", self.name)
  }
}

#########################################################
##### Cloud Init User Data
#########################################################

resource "local_file" "user_data_freeipa" {
  content  = data.template_file.user_data_freeipa.rendered
  filename = "/tmp/${var.domain_name}_freeipa/user-data"
}

data "template_file" "user_data_freeipa" {
  template = <<EOF
#cloud-config
hostname: freeipa.${var.domain_name}
users:
  - default
  - name: ${var.admin_username}
    plain_text_passwd: ${var.admin_password}
    primary_group: hashicorp
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    lock_passwd: false
    ssh_authorized_keys:
      - ${var.admin_ssh_public_key}
runcmd:

### Cleanup network configuration

  - nmcli connection migrate
  - rm /etc/NetworkManager/system-connections/*
  - systemctl restart NetworkManager
  - nmcli connection delete ens3  
  - nmcli connection modify id "Wired connection 1" connection.id ens3
  - nmcli connection modify ens3 ipv4.addresses ${var.freeipa_ip}
  - nmcli connection modify ens3 ipv4.gateway ${var.freeipa_gateway}
  - nmcli connection modify ens3 ipv4.dns ${var.freeipa_dns}
  - nmcli connection modify ens3 ipv4.method manual
  - nmcli connection modify ens3 ipv6.method disabled  
  - nmcli connection down ens3
  - nmcli connection up ens3

### Update and rename host

  - dnf update -y
  - hostnamectl set-hostname freeipa.test.lab

### Install FreeIPA

  - dnf install -y epel-release
  - dnf install -y ipa-server ipa-server-dns bind-dyndb-ldap --nobest
  - ipa-server-install -U --hostname=freeipa.test.lab --realm=TEST.LAB --domain=test.lab --ds-password=${var.freeipa_password} --admin-password=${var.freeipa_password} --setup-dns --auto-reverse --no-ntp --forwarder=1.1.1.1
  - firewall-cmd --add-service={freeipa-ldap,freeipa-ldaps,freeipa-replication,kerberos,dns,ntp,kpasswd,http,https} --permanent
  - firewall-cmd --zone=public --add-port=53/tcp --permanent
  - firewall-cmd --zone=public --add-port=80/tcp --permanent
  - firewall-cmd --zone=public --add-port=88/tcp --permanent
  - firewall-cmd --zone=public --add-port=389/tcp --permanent
  - firewall-cmd --zone=public --add-port=443/tcp --permanent
  - firewall-cmd --zone=public --add-port=464/tcp --permanent
  - firewall-cmd --zone=public --add-port=636/tcp --permanent

### Configure network for FreeIPA

  - nmcli connection modify ens3 ipv4.dns ${var.freeipa_dns_server}
  - nmcli connection down ens3
  - nmcli connection up ens3

### Configure Prometheus Node Exporter

  - dnf install -y wget tar
  - wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
  - tar xvfz node_exporter-1.5.0.linux-amd64.tar.gz
  - sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/

  - echo "[Unit]" >> /etc/systemd/system/node_exporter.service
  - echo "Description=Node Exporter" >> /etc/systemd/system/node_exporter.service
  - echo "Wants=network-online.target" >> /etc/systemd/system/node_exporter.service
  - echo "After=network-online.target" >> /etc/systemd/system/node_exporter.service
  - echo "[Service]" >> /etc/systemd/system/node_exporter.service
  - echo "User=node_exporter" >> /etc/systemd/system/node_exporter.service
  - echo "ExecStart=/usr/local/bin/node_exporter" >> /etc/systemd/system/node_exporter.service
  - echo "[Install]" >> /etc/systemd/system/node_exporter.service
  - echo "WantedBy=default.target" >> /etc/systemd/system/node_exporter.service

  - useradd --no-create-home --shell /bin/false node_exporter
  - chown node_exporter:node_exporter /usr/local/bin/node_exporter
  - firewall-cmd --zone=public --add-port=9100/tcp --permanent
  - chcon --reference=/bin/less /usr/local/bin/node_exporter
  - semanage fcontext -a -t bin_t "/usr/localbin/node_exporter"
  - systemctl enable node_exporter

### Install virtualization extensions

  - sudo dnf install -y libvirt virt-install bridge-utils
  - sudo systemctl enable libvirtd
  - sudo usermod -aG libvirt $(whoami)
  - sudo usermod -aG kvm $(whoami)
  - sudo systemctl enable qemu-guest-agent

### Disable cloud-init

  - systemctl disable cloud-init
  
### Reboot

  - reboot

EOF
}

#########################################################
##### Cloud Init Meta Data
#########################################################

resource "local_file" "meta_data_freeipa" {
  content  = data.template_file.meta_data_freeipa.rendered
  filename = "/tmp/${var.domain_name}_freeipa/meta-data"
}

data "template_file" "meta_data_freeipa" {
  template = <<EOF
instance-id: freeipa
local-hostname: freeipa
EOF
}

#########################################################
##### Cloud Init ISO Image
#########################################################

resource "null_resource" "create_cloud_init_iso_freeipa" {
  provisioner "local-exec" {
    command = <<EOF
      genisoimage -output /tmp/${var.domain_name}_cloud-init-freeipa.iso -volid cidata -joliet -rock /tmp/${var.domain_name}_freeipa/user-data /tmp/${var.domain_name}_freeipa/meta-data
EOF
  }

  depends_on = [
    local_file.user_data_freeipa,
    local_file.meta_data_freeipa
  ]
}

resource "libvirt_volume" "cloud_init_iso_freeipa" {
  name   = "${var.domain_name}_cloud-init-freeipa.iso"
  pool   = "default"
  source = "/tmp/${var.domain_name}_cloud-init-freeipa.iso"
  format = "raw"

  depends_on = [
    null_resource.create_cloud_init_iso_freeipa
  ]
}
