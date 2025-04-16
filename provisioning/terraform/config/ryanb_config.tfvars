### must specify tfvars during changes:  terraform plan -var-file="config.tfvars"

#########################################################
##### Test Lab
#########################################################

centos9_image_source_path = "/src/testlab/provisioning/terraform/image/CentOS-Stream-9-latest-x86_64.qcow2"
#centos9_image_source_path = "/mnt/ssd/src/testlab/provisioning/terraform/image/CentOS-Stream-9-latest-x86_64.qcow2"

domain_name = "test.lab"

admin_username = "admin"
admin_password = "testlab"
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9AMEmxnr6+FUDYarF227VXugs9ac8kiX+Z/yBJb3/iEAw9f5xIutW0Z3Fpd2ir509zjqNiAsgtJGSLaigxVuSeLvqqYonHOQxk31M/YYhVxuNxB1VSTmQudJeGRuDV2MgX7/dNUTbMmjyNS/iYnGw21O4ylgqxK7RQg2YtiQp8nvG7vwZeow7uyAPBYqsGAzP0i6O2oXfH4ZbaJOXy/62ScfqdxjXS7vZPBxVmJ9RqeGL/uLJnfcNcIIzOH95p1zy/tj3/c4lfmBb9+n/cAJ0IVvbc9SXhw/rtYTZVddTBjTPvNgU7etgmrGwWJ7TeTeoEF4bx7uR7JldR2gzYFeoMhqOkPOgvCu7qt4t6mG9pKFSDhuYKp9l1iL9VuKYaoEviFlg8Nv4BFn39YVz+1flKoednSsp/u8j31Ooof09c/uli6lFv3bckbBerSemq87psmX+XYRoxw4DhTjg87wsnKgOHM9zr0rqWWRwFKo7aHsCziliJpQsHSE8+JxW4GThjjb7+9kyG7KRTaJ3JBW/kcXbBuUbDAWgQn+GY8xW3+SBpvsxx+Op8mveWETOmgk94ZEVvsr1tTBj7eIRTRgbO5ycIF8MvseXJDD1OSMOcboTmmY+VcDabuV+FTmiCtN9GWkdycSPbzAHnjZMmV81dOp0USzqXc2Nd3Tw4Qgbiw== admin@test.lab"

connection_name = "\"System ens3\""

#########################################################
##### FreeIPA
#########################################################

freeipa_deploy_machine = true

freeipa_cpu_count       = 2
freeipa_memory_size     = 2048
freeipa_ip              = "10.0.0.200/24"
freeipa_dns_server		= "10.0.0.200"
freeipa_gateway         = "10.0.0.1"
freeipa_dns             = "1.1.1.1"
freeipa_password		= "testlabs"

#########################################################
##### Puppet
#########################################################

puppet_deploy_machine = true

puppet_cpu_count        = 2
puppet_memory_size      = 4096
puppet_ip               = "10.0.0.201/24"
puppet_gateway          = "10.0.0.1"
puppet_dns              = "1.1.1.1"

#########################################################
##### Prometheus
#########################################################

prometheus_deploy_machine = false

prometheus_cpu_count        = 2
prometheus_memory_size      = 4096
prometheus_ip               = "10.0.0.220/24"
prometheus_gateway          = "10.0.0.1"
prometheus_dns              = "1.1.1.1"

#########################################################
##### Grafana
#########################################################

grafana_deploy_machine = true

grafana_cpu_count        = 2
grafana_memory_size      = 4096
grafana_ip               = "192.168.1.218/24"
grafana_gateway          = "192.168.1.254"
grafana_dns              = "1.1.1.1"

#########################################################
##### Kcontrol
#########################################################

kcontrol_machine_count	= 0

kcontrol_ips 			= ["10.0.0.240","10.0.0.241","10.0.0.242"]
kcontrol_cpu_count       = 2
kcontrol_memory_size     = 2048
kcontrol_gateway         = ""
kcontrol_dns             = "1.1.1.1"

#########################################################
##### Kworker
#########################################################

kworker_machine_count	= 2

kworker_ips 			= ["10.0.0.210","10.0.0.211","10.0.0.212","1.0.0.213","10.0.0.214","10.0.0.215","10.0.0.216","10.0.0.217","10.0.0.218","10.0.0.219"]
kworker_cpu_count       = 2
kworker_memory_size     = 2048
kworker_gateway         = "10.0.0.1"
kworker_dns             = "1.1.1.1"

#########################################################
##### HAProxy
#########################################################

haproxy_machine_count	= 0

haproxy_ips 			= ["10.0.0.230","10.0.0.231","10.0.0.232"]
haproxy_cpu_count       = 2
haproxy_memory_size     = 2048
haproxy_gateway         = "10.0.0.1"
haproxy_dns             = "1.1.1.1"
