#########################################################
##### Test Lab
#########################################################

variable "centos9_image_source_path" {
  description = "Path to CentOS Stream 9 base image"
  type        = string
}

variable "domain_name" {
  description = "test.lab"
  type        = string
}

variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "connection_name" {
  description = "Network connection name"
  type        = string
}

variable "public_network" {
  description = "Network connection name"
  type        = string
}

variable "private_network" {
  description = "Network connection name"
  type        = string
}

#########################################################
##### FreeIPA
#########################################################

variable "freeipa_deploy_machine" {
  description = "Whether to deploy the machine (true/false)"
  type        = bool
  default     = true
}

variable "freeipa_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "freeipa_memory_size" {
  description = "Memory size"
  type        = number
}

variable "freeipa_ip" {
  description = "The static IP address for the FreeIPA server"
  type        = string
}

variable "freeipa_dns_server" {
  description = "Address of the FreeIPA DNS service"
  type        = string
}

variable "freeipa_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "freeipa_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

variable "freeipa_password" {
  description = "FreeIPA Admin password"
  type        = string
}


#########################################################
##### Puppet
#########################################################

variable "puppet_deploy_machine" {
  description = "Whether to deploy the machine (true/false)"
  type        = bool
  default     = true
}

variable "puppet_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "puppet_memory_size" {
  description = "Memory size"
  type        = number
}

variable "puppet_ip" {
  description = "The static IP address for the FreeIPA server"
  type        = string
}

variable "puppet_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "puppet_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

#########################################################
##### OpenVPN
#########################################################

variable "openvpn_deploy_machine" {
  description = "Whether to deploy the machine (true/false)"
  type        = bool
  default     = true
}

variable "openvpn_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "openvpn_memory_size" {
  description = "Memory size"
  type        = number
}

variable "openvpn_ip" {
  description = "The static IP address for the FreeIPA server"
  type        = string
}

variable "openvpn_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "openvpn_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

variable "openvpn_private_ip" {
  description = "The static IP address for the FreeIPA server"
  type        = string
}

#########################################################
##### Prometheus
#########################################################

variable "prometheus_deploy_machine" {
  description = "Whether to deploy the machine (true/false)"
  type        = bool
  default     = true
}

variable "prometheus_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "prometheus_memory_size" {
  description = "Memory size"
  type        = number
}

variable "prometheus_ip" {
  description = "The static IP address for the Prometheus server"
  type        = string
}

variable "prometheus_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "prometheus_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

#########################################################
##### Grafana
#########################################################

variable "grafana_deploy_machine" {
  description = "Whether to deploy the machine (true/false)"
  type        = bool
  default     = true
}

variable "grafana_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "grafana_memory_size" {
  description = "Memory size"
  type        = number
}

variable "grafana_ip" {
  description = "The static IP address for the Prometheus server"
  type        = string
}

variable "grafana_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "grafana_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

#########################################################
##### Kcontrol
#########################################################

variable "kcontrol_machine_count" {
  description = "Machine count"
  type        = number
}

variable "kcontrol_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "kcontrol_memory_size" {
  description = "Memory size"
  type        = number
}

variable "kcontrol_ips" {
  description = "The static IP address for the Kworker server"
  type        = list(string)
}

variable "kcontrol_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "kcontrol_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}


#########################################################
##### Kworker
#########################################################

variable "kworker_machine_count" {
  description = "Machine count"
  type        = number
}

variable "kworker_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "kworker_memory_size" {
  description = "Memory size"
  type        = number
}

variable "kworker_ips" {
  description = "The static IP address for the Kworker server"
  type        = list(string)
}

variable "kworker_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "kworker_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}

#########################################################
##### HAProxy
#########################################################

variable "haproxy_machine_count" {
  description = "Machine count"
  type        = number
}

variable "haproxy_cpu_count" {
  description = "CPU count"
  type        = number
}

variable "haproxy_memory_size" {
  description = "Memory size"
  type        = number
}

variable "haproxy_ips" {
  description = "The static IP address for the Kworker server"
  type        = list(string)
}

variable "haproxy_gateway" {
  description = "The gateway for the static IP address"
  type        = string
}

variable "haproxy_dns" {
  description = "The DNS server for the static IP address"
  type        = string
}
