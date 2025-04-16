### must specify tfvars during changes:  terraform plan -var-file="config.tfvars"

#########################################################
##### Test Lab
#########################################################

centos9_image_source_path = "/src/testlab/provisioning/terraform/image/CentOS-Stream-9-latest-x86_64.qcow2"
domain_name = "test.lab"

admin_username = "admin"
admin_password = "testlab"
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0c0gF23+OCMPNq5UnkMhyQ3HJXO3rIBydl8NwvNJktVoZPkjC3qXAv8SFTQ9mR4YTDXxS9qQT/NOZhSlmefnc5LvLGYTCTnhYc0kiWR+dssrM30oFDuMVVsSymAV+jNzWFzMO4Jwjkl5MiKwPFrGvUBmpaPVcmN/cdQL5S0wUHaFSa0J1kGr3dEeTeh61SUB12Mn1Qg9Gq75j+cgA6OhMlyiTr/EFWvJblCy5pXva4X7v+HdXRDIw86gzkl/m/Fm+EYyCMqo0uCSe5ctaguXAHswjniUh3eISCWrOT6NOjhP9tDyINsvNEEcBzuodEMND6WyRHNxZrTIXvCFKVUf05bHmTenft2zFSYIf8klltZ1Tjj4QKy9dtg6k48xNhHImPIGGTel85UKytoYXmJ+9iuVYaJSjFf5CGSMrS6xHaqoMq/O/AY15jNNrip3MkBT2dW7SfV+fBuluUhx3zb/Qdi0mXaA8zWbv7BPK/vrTQ2R+njIvndXOysHbYOqE4/MsG4FOt392sCHRdT7Gd8VR25hPZCnJGLELGxcj+OTmEgN7ctA74MdvQwfdYOoIDRkAi03zJnwOmbYkZ03t5vYEMUkVwV7bZrjqtS5sf7A+La2IW8A7e0u3oEMf6N8b+9cDG552aPpHO4Q2ut5w8QUuIcYBCSUy8TiKRxn7RVcJ/w== admin@test.lab"

connection_name = "\"System ens3\""

public_network = "br0"
private_network = "isolated-net"

#########################################################
##### OpenVPN
#########################################################

openvpn_deploy_machine = true

openvpn_cpu_count        = 2
openvpn_memory_size      = 4096
openvpn_ip               = "192.168.1.1/24"
openvpn_gateway          = "192.168.1.254"
openvpn_dns              = "1.1.1.1"
openvpn_private_ip       = "192.168.200.254/24"

#########################################################
##### FreeIPA
#########################################################

freeipa_deploy_machine = true

freeipa_cpu_count       = 24
freeipa_memory_size     = 4096
freeipa_ip              = "192.168.200.215/24"
freeipa_dns_server		= "192.168.200.215"
freeipa_gateway         = "192.168.200.254"
freeipa_dns             = "1.1.1.1"
freeipa_password		= "testlabs"

#########################################################
##### Puppet
#########################################################

puppet_deploy_machine = true

puppet_cpu_count        = 2
puppet_memory_size      = 4096
puppet_ip               = "192.168.200.216/24"
puppet_gateway          = "192.168.200.254"
puppet_dns              = "1.1.1.1"

#########################################################
##### Prometheus
#########################################################

prometheus_deploy_machine = true

prometheus_cpu_count        = 2
prometheus_memory_size      = 4096
prometheus_ip               = "192.168.200.217/24"
prometheus_gateway          = "192.168.200.254"
prometheus_dns              = "1.1.1.1"

#########################################################
##### Grafana
#########################################################

grafana_deploy_machine = true

grafana_cpu_count        = 2
grafana_memory_size      = 4096
grafana_ip               = "192.168.200.218/24"
grafana_gateway          = "192.168.200.254"
grafana_dns              = "1.1.1.1"

#########################################################
##### Kcontrol
#########################################################

kcontrol_machine_count	= 1

kcontrol_ips 			= ["192.168.200.140","192.168.200.141","192.168.200.142"]
kcontrol_cpu_count       = 2
kcontrol_memory_size     = 2048
kcontrol_gateway         = "192.168.200.254"
kcontrol_dns             = "1.1.1.1"

#########################################################
##### Kworker
#########################################################

kworker_machine_count	= 1

kworker_ips 			= ["192.168.200.150","192.168.200.151","192.168.200.152","192.168.200.153","192.168.200.154","192.168.200.155","192.168.200.156","192.168.200.157","192.168.200.158","192.168.200.159"]
kworker_cpu_count       = 2
kworker_memory_size     = 2048
kworker_gateway         = "192.168.200.254"
kworker_dns             = "1.1.1.1"

#########################################################
##### HAProxy
#########################################################

haproxy_machine_count	= 2

haproxy_ips 			= ["192.168.200.130","192.168.200.131","192.168.200.132"]
haproxy_cpu_count       = 2
haproxy_memory_size     = 2048
haproxy_gateway         = "192.168.200.254"
haproxy_dns             = "1.1.1.1"
