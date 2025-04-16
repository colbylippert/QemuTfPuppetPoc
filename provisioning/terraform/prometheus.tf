#########################################################
##### CentOS Base Image
#########################################################

resource "libvirt_volume" "centos9_image_prometheus" {
  name   = "CentOS-Stream-9-x86_64-${var.domain_name}_prometheus.qcow2"
  pool   = "default"
  source = var.centos9_image_source_path
  format = "qcow2"
}

#########################################################
##### CentOS Virtual Machine
#########################################################

resource "libvirt_domain" "centos9_prometheus" {
  count = var.prometheus_deploy_machine ? 1 : 0

  name   = "prometheus.${var.domain_name}"
  memory = var.prometheus_memory_size
  vcpu   = var.prometheus_cpu_count

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.centos9_image_prometheus.id
  }

  disk {
    volume_id = libvirt_volume.cloud_init_iso_prometheus.id
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
    local_file.user_data_prometheus,
    local_file.meta_data_prometheus
  ]

  provisioner "local-exec" {
    command = format("virsh autostart %s", self.name)
  }  
}

#########################################################
##### Cloud Init User Data
#########################################################

resource "local_file" "user_data_prometheus" {
  content  = data.template_file.user_data_prometheus.rendered
  filename = "/tmp/${var.domain_name}_prometheus/user-data"
}

data "template_file" "user_data_prometheus" {
  template = <<EOF
#cloud-config
hostname: prometheus.${var.domain_name}
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
  - nmcli connection modify ens3 ipv4.addresses ${var.prometheus_ip}
  - nmcli connection modify ens3 ipv4.gateway ${var.prometheus_gateway}
  - nmcli connection modify ens3 ipv4.dns ${var.prometheus_dns}
  - nmcli connection modify ens3 ipv4.method manual
  - nmcli connection modify ens3 ipv6.method disabled  
  - nmcli connection down ens3
  - nmcli connection up ens3

### Update and rename host

  - dnf update -y
  - hostnamectl set-hostname prometheus.test.lab

### Install Prometheus

  - dnf install tar wget -y
  - wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
  - tar xvf prometheus-2.43.0.linux-amd64.tar.gz
  - mv prometheus-2.43.0.linux-amd64/prometheus /usr/local/bin/
  - mv prometheus-2.43.0.linux-amd64/promtool /usr/local/bin/
  - useradd --no-create-home --shell /bin/false prometheus
  - mkdir /etc/prometheus
  - mkdir /var/lib/prometheus
  - chown prometheus:prometheus /etc/prometheus
  - chown prometheus:prometheus /var/lib/prometheus
  - chown prometheus:prometheus /usr/local/bin/prometheus
  - chown prometheus:prometheus /usr/local/bin/promtool
  - cp prometheus-2.43.0.linux-amd64/prometheus.yml /etc/prometheus/
  - cp -r prometheus-2.43.0.linux-amd64/consoles /etc/prometheus/
  - cp -r prometheus-2.43.0.linux-amd64/console_libraries /etc/prometheus/
  - chown -R prometheus:prometheus /etc/prometheus/consoles
  - chown -R prometheus:prometheus /etc/prometheus/console_libraries
  - chown prometheus:prometheus /etc/prometheus/prometheus.yml

  - echo "[Unit]" > /etc/systemd/system/prometheus.service
  - echo "Description=Prometheus" >> /etc/systemd/system/prometheus.service
  - echo "Wants=network-online.target" >> /etc/systemd/system/prometheus.service
  - echo "After=network-online.target" >> /etc/systemd/system/prometheus.service
  - echo "" >> /etc/systemd/system/prometheus.service
  - echo "[Service]" >> /etc/systemd/system/prometheus.service
  - echo "User=prometheus" >> /etc/systemd/system/prometheus.service
  - echo "Group=prometheus" >> /etc/systemd/system/prometheus.service
  - echo "Type=simple" >> /etc/systemd/system/prometheus.service
  - echo "ExecStart=/usr/local/bin/prometheus \\" >> /etc/systemd/system/prometheus.service
  - echo "    --config.file /etc/prometheus/prometheus.yml \\" >> /etc/systemd/system/prometheus.service
  - echo "    --storage.tsdb.path /var/lib/prometheus/ \\" >> /etc/systemd/system/prometheus.service
  - echo "    --web.console.templates=/etc/prometheus/consoles \\" >> /etc/systemd/system/prometheus.service
  - echo "    --web.console.libraries=/etc/prometheus/console_libraries" >> /etc/systemd/system/prometheus.service
  - echo "" >> /etc/systemd/system/prometheus.service
  - echo "[Install]" >> /etc/systemd/system/prometheus.service
  - echo "WantedBy=multi-user.target" >> /etc/systemd/system/prometheus.service

#  - echo "alerting:" > /etc/prometheus/prometheus.yml
#  - echo "  alertmanagers:" >> /etc/prometheus/prometheus.yml
#  - echo "    - static_configs:" >> /etc/prometheus/prometheus.yml
#  - echo "    - targets: null" >> /etc/prometheus/prometheus.yml
#  - echo "global:" >> /etc/prometheus/prometheus.yml
#  - echo "evaluation_interval: 15s" >> /etc/prometheus/prometheus.yml
#  - echo "scrape_interval: 15s" >> /etc/prometheus/prometheus.yml
#  - echo "rule_files: null" >> /etc/prometheus/prometheus.yml
#  - echo "scrape_configs:" >> /etc/prometheus/prometheus.yml
#  - echo "- job_name: prometheus" >> /etc/prometheus/prometheus.yml
#  - echo "static_configs:" >> /etc/prometheus/prometheus.yml
#  - echo "- targets: ['freeipa.test.lab:9100','grafana.test.lab:9100','prometheus.test.lab:9090','puppet.test.lab:9100','openvpn.test.lab:9100','kcontrol1.test.lab:9100','kcontrol2.test.lab:9100','kcontrol3.test.lab:9100','kworker1.test.lab:9100','kworker2.test.lab:9100','kworker3.test.lab:9100','kworker4.test.lab:9100','kworker5.test.lab:9100','kworker6.test.lab:9100','kworker7.test.lab:9100','kworker8.test.lab:9100','kworker9.test.lab:9100','kworker10.test.lab:9100']" >> /etc/prometheus/prometheus.yml

  - systemctl daemon-reload
  - systemctl enable prometheus
  - chcon --reference=/bin/less /usr/local/bin/prometheus
  - semanage fcontext -a -t bin_t "/usr/localbin/prometheus"
  - firewall-cmd --zone=public --add-port=9090/tcp --permanent
  - firewall-cmd --zone=public --add-port=9093/tcp --permanent

#  - sed -i '/- targets:/c\      - targets: ["freeipa.test.lab:9090","puppet.test.lab:9100","prometheus.test.lab:9100","grafana.test.lab:9100","kcontrol1.test.lab:9100","kcontrol2.test.lab:9100","kcontrol3.test.lab:9100","haproxy1.test.lab:9100","haproxy2.test.lab:9100","haproxy3.test.lab:9100","kworker1.test.lab:9100","kworker2.test.lab:9100","kworker3.test.lab:9100","kworker4.test.lab:9100","kworker5.test.lab:9100","kworker6.test.lab:9100","kworker7.test.lab:9100","kworker8.test.lab:9100","kworker9.test.lab:9100","kworker10.test.lab:9100"]' /etc/prometheus/prometheus.yml

### Configure network for FreeIPA

  - dnf install nc -y
  - ["sh", "-c", "until nc -z ${var.freeipa_dns_server} 389; do echo 'Waiting for FreeIPA: LDAP'; sleep 1; done;"]
  - echo "Sleeping 60 seconds before FreeIPA client install"; sleep 60;

  - nmcli connection modify ens3 ipv4.dns ${var.freeipa_dns_server}
  - nmcli connection down ens3
  - nmcli connection up ens3

  - dnf install -y ipa-client
  - ipa-client-install --domain=test.lab --server=freeipa.test.lab --realm=TEST.LAB --principal=admin --password=testlabs --mkhomedir --enable-dns-updates --unattend

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

  - ["sh", "-c", "until nc -z puppet.test.lab 8140; do echo 'Waiting for PuppetServer: TCP 8140'; sleep 1; done;"]
  - systemctl enable puppet
  - systemctl start puppet
  - /opt/puppetlabs/bin/puppet agent -t --debug

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

resource "local_file" "meta_data_prometheus" {
  content  = data.template_file.meta_data_prometheus.rendered
  filename = "/tmp/${var.domain_name}_prometheus/meta-data"
}

data "template_file" "meta_data_prometheus" {
  template = <<EOF
instance-id: prometheus
local-hostname: prometheus
EOF
}

#########################################################
##### Cloud Init ISO Image
#########################################################

resource "null_resource" "create_cloud_init_iso_prometheus" {
  provisioner "local-exec" {
    command = <<EOF
      genisoimage -output /tmp/${var.domain_name}_cloud-init-prometheus.iso -volid cidata -joliet -rock /tmp/${var.domain_name}_prometheus/user-data /tmp/${var.domain_name}_prometheus/meta-data
EOF
  }

  depends_on = [
    local_file.user_data_prometheus,
    local_file.meta_data_prometheus
  ]
}

resource "libvirt_volume" "cloud_init_iso_prometheus" {
  name   = "${var.domain_name}_cloud-init-prometheus.iso"
  pool   = "default"
  source = "/tmp/${var.domain_name}_cloud-init-prometheus.iso"
  format = "raw"

  depends_on = [
    null_resource.create_cloud_init_iso_prometheus
  ]
}
