#########################################################
##### CentOS Base Image
#########################################################

resource "libvirt_volume" "centos9_image_puppet" {
  name   = "CentOS-Stream-9-x86_64-${var.domain_name}_puppet.qcow2"
  pool   = "default"
  source = var.centos9_image_source_path
  format = "qcow2"
}

#########################################################
##### CentOS Virtual Machine
#########################################################

resource "libvirt_domain" "centos9_puppet" {
  count = var.puppet_deploy_machine ? 1 : 0

  name   = "puppet.${var.domain_name}"
  memory = var.puppet_memory_size
  vcpu   = var.puppet_cpu_count

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.centos9_image_puppet.id
  }

  disk {
    volume_id = libvirt_volume.cloud_init_iso_puppet.id
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
    local_file.user_data_puppet,
    local_file.meta_data_puppet
  ]

  provisioner "local-exec" {
    command = format("virsh autostart %s", self.name)
  }  
}

#########################################################
##### Cloud Init User Data
#########################################################

resource "local_file" "user_data_puppet" {
  content  = data.template_file.user_data_puppet.rendered
  filename = "/tmp/${var.domain_name}_puppet/user-data"
}

data "template_file" "user_data_puppet" {
  template = <<EOF
#cloud-config
hostname: puppet.${var.domain_name}
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
  - nmcli connection modify ens3 ipv4.addresses ${var.puppet_ip}
  - nmcli connection modify ens3 ipv4.gateway ${var.puppet_gateway}
  - nmcli connection modify ens3 ipv4.dns ${var.puppet_dns}
  - nmcli connection modify ens3 ipv4.method manual
  - nmcli connection modify ens3 ipv6.method disabled  
  - nmcli connection down ens3
  - nmcli connection up ens3

### Update and rename host

  - dnf update -y
  - hostnamectl set-hostname puppet.${var.domain_name}

### Install Puppet server

  - dnf install https://yum.puppet.com/puppet8-release-el-9.noarch.rpm -y
  - dnf update -y
  - dnf install puppetserver -y
  - systemctl enable puppetserver
  - /opt/puppetlabs/bin/puppet config set certname puppet.${var.domain_name} --section main
  - /opt/puppetlabs/bin/puppet config set server puppet.${var.domain_name} --section main
  - /opt/puppetlabs/bin/puppet config set environment production --section main
  - /opt/puppetlabs/bin/puppet config set runinterval 1m --section main
  - echo "[master]" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "autosign = true" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "*" > /etc/puppetlabs/puppet/autosign.conf
  - systemctl enable puppetserver
  - firewall-cmd --zone=public --add-port=8140/tcp --permanent
  - firewall-cmd --zone=public --add-port=443/tcp --permanent
  - firewall-cmd --zone=public --add-port=8081/tcp --permanent
  - firewall-cmd --reload

### Configure Puppet Agent

  - rpm -Uvh https://yum.puppet.com/puppet8-release-el-9.noarch.rpm
  - dnf update -y
  - dnf install -y puppet-agent

  - echo "[main]" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "certname = $(hostname -f)" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "server = puppet.${var.domain_name}" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "environment = production" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "runinterval = 1m" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "[agent]" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "report = true" >> /etc/puppetlabs/puppet/puppet.conf
  - echo "ignoreschedules = true" >> /etc/puppetlabs/puppet/puppet.conf

  - systemctl enable puppet
  - systemctl start puppet
  - /opt/puppetlabs/bin/puppet agent -t --debug

### Configure network for FreeIPA

  - dnf install nc -y
  - ["sh", "-c", "until nc -z ${var.freeipa_dns_server} 389; do echo 'Waiting for FreeIPA: LDAP'; sleep 1; done;"]
  - echo "Sleeping 60 seconds before FreeIPA client install"; sleep 60;

  - nmcli connection modify ens3 ipv4.dns ${var.freeipa_dns_server}
  - nmcli connection down ens3
  - nmcli connection up ens3

  - dnf install -y ipa-client
  - ipa-client-install --domain=test.lab --server=freeipa.test.lab --realm=TEST.LAB --principal=admin --password=testlabs --mkhomedir --enable-dns-updates --unattend

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

resource "local_file" "meta_data_puppet" {
  content  = data.template_file.meta_data_puppet.rendered
  filename = "/tmp/${var.domain_name}_puppet/meta-data"
}

data "template_file" "meta_data_puppet" {
  template = <<EOF
instance-id: puppet
local-hostname: puppet
EOF
}

#########################################################
##### Cloud Init ISO Image
#########################################################

resource "null_resource" "create_cloud_init_iso_puppet" {
  provisioner "local-exec" {
    command = <<EOF
      genisoimage -output /tmp/${var.domain_name}_cloud-init-puppet.iso -volid cidata -joliet -rock /tmp/${var.domain_name}_puppet/user-data /tmp/${var.domain_name}_puppet/meta-data
EOF
  }

  depends_on = [
    local_file.user_data_puppet,
    local_file.meta_data_puppet
  ]
}

resource "libvirt_volume" "cloud_init_iso_puppet" {
  name   = "${var.domain_name}_cloud-init-puppet.iso"
  pool   = "default"
  source = "/tmp/${var.domain_name}_cloud-init-puppet.iso"
  format = "raw"

  depends_on = [
    null_resource.create_cloud_init_iso_puppet
  ]
}
