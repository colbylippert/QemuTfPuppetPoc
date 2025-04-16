# QEMU/KVM Terraform & Puppet Test Lab Overview

## 1. Introduction & Architecture Overview

This document provides an overview of the QEMU/KVM test lab environment provisioned using Terraform and configured with Puppet. The goal is to create a flexible virtual lab consisting of various interconnected services like FreeIPA, Puppet, Kubernetes, HAProxy, Prometheus, Grafana, and OpenVPN.

**Technologies Used:**

*   **Virtualization:** QEMU/KVM managed via Libvirt
*   **Infrastructure Provisioning:** Terraform (using the `dmacvicar/libvirt` provider)
*   **Initial VM Configuration:** Cloud-Init
*   **Configuration Management:** Puppet

**Architecture Diagram:**

![Architecture Overview](images/overview.jpg)

## 2. Terraform Infrastructure (`provisioning/terraform/`)

Terraform is used to define and manage the virtual machine infrastructure on a QEMU/KVM hypervisor via Libvirt.

### Providers (`providers.tf`)

*   **`dmacvicar/libvirt` (v0.7.6):** The primary provider used to interact with the Libvirt API (`qemu:///system`) for creating and managing VMs, volumes, and networks.
*   **`hashicorp/null` (v3.1.0):** Used for resources that don't directly manage infrastructure but are needed for tasks like triggering local scripts (e.g., ISO generation).
*   **`local`:** Used for managing local files (e.g., creating Cloud-Init user-data files).

### Variables (`variables.tf`)

This file defines numerous variables to customize the deployment:

*   **General:** `centos9_image_source_path`, `domain_name`, `admin_username`, `admin_password`, `admin_ssh_public_key`, `connection_name`, `public_network`, `private_network`.
*   **Role-Specific:** For each VM role (FreeIPA, Puppet, OpenVPN, Prometheus, Grafana, Kcontrol, Kworker, HAProxy), variables control:
    *   Deployment Toggles (`*_deploy_machine` or `*_machine_count`).
    *   Resource Allocation (`*_cpu_count`, `*_memory_size`).
    *   Network Configuration (`*_ip(s)`, `*_gateway`, `*_dns`, `openvpn_private_ip`).
    *   Credentials (`freeipa_password`).

### VM Definitions (Role-Specific `.tf` files)

A consistent pattern is used across the `.tf` files (`freeipa.tf`, `puppet.tf`, etc.) to define VMs:

1.  **Base Image Volume (`libvirt_volume`):** Clones the base CentOS 9 image (`var.centos9_image_source_path`) for each VM or set of VMs (using `count` for scalable roles). The volume name includes the role and domain name.
2.  **Cloud-Init ISO Generation:**
    *   `local_file`: Creates temporary `user-data` and `meta-data` files based on `template_file` resources.
    *   `template_file`: Renders the Cloud-Init configuration, injecting variables.
    *   `null_resource` (`create_cloud_init_iso_*`): Uses `local-exec` to run `genisoimage` and create a Cloud-Init ISO from the temporary files.
    *   `libvirt_volume` (`cloud_init_iso_*`): Uploads the generated ISO to the Libvirt storage pool.
3.  **Virtual Machine (`libvirt_domain`):**
    *   Defines the VM with name, vCPU (`vcpu`), and memory (`memory`) based on variables. Uses `count` for roles like kcontrol, kworker, and haproxy.
    *   Sets CPU mode to `host-passthrough`.
    *   Attaches the cloned base image disk and the Cloud-Init ISO disk.
    *   Connects network interfaces, typically to `var.private_network`. The OpenVPN server also connects to `var.public_network`.
    *   Configures serial console (`pty`) and VNC graphics.
    *   Uses `depends_on` to ensure Cloud-Init files are created before the VM.
    *   Uses `local-exec` provisioner to run `virsh autostart` on the created VM.

## 3. Cloud-Init Bootstrapping

Cloud-Init is used via an attached ISO to perform the initial configuration of each VM upon first boot. The `user-data` file within the ISO contains a `runcmd` sequence.

### Common Steps (Executed on most VMs):

1.  **Set Hostname:** Configures the VM's hostname (e.g., `puppet.${var.domain_name}`).
2.  **Create Admin User:** Creates the user specified by `var.admin_username` with password (`var.admin_password`), sudo privileges, and adds the SSH public key (`var.admin_ssh_public_key`).
3.  **Network Configuration:** Cleans up default NetworkManager connections and configures the primary interface (`ens3`, sometimes `ens4` for OpenVPN) with a static IP, gateway, and DNS using variables specific to the VM's role (e.g., `var.puppet_ip`, `var.puppet_gateway`, `var.puppet_dns`).
4.  **System Updates:** Runs `dnf update -y`.
5.  **FreeIPA Client Setup:**
    *   Installs `nc` (netcat).
    *   Waits until the FreeIPA server's LDAP port (389) is reachable (`nc -z ${var.freeipa_dns_server} 389`).
    *   Waits an additional 60 seconds.
    *   Updates the VM's DNS to point to the FreeIPA server (`var.freeipa_dns_server`).
    *   Installs `ipa-client`.
    *   Runs `ipa-client-install` to join the domain (uses hardcoded domain `test.lab`, realm `TEST.LAB`, principal `admin`, password `testlabs`).
6.  **Puppet Agent Setup:**
    *   Installs the Puppet 8 release RPM and the `puppet-agent` package.
    *   Configures `/etc/puppetlabs/puppet/puppet.conf` with the server (`puppet.${var.domain_name}`), environment (`production`), run interval (`1m`), and certname (`$(hostname -f)`).
    *   Waits until the Puppet Server port (8140) is reachable (`nc -z puppet.test.lab 8140`).
    *   Enables and starts the `puppet` service.
    *   Runs `puppet agent -t --debug` to trigger the first run.
7.  **Prometheus Node Exporter Installation:**
    *   Installs `wget` and `tar`.
    *   Downloads Node Exporter binary (v1.5.0).
    *   Moves the binary to `/usr/local/bin/`.
    *   Creates a `node_exporter` user.
    *   Creates a systemd service file (`/etc/systemd/system/node_exporter.service`).
    *   Sets ownership and permissions.
    *   Opens firewall port 9100/tcp.
    *   Handles SELinux context (`chcon`, `semanage fcontext`).
    *   Enables the `node_exporter` service.
8.  **Virtualization Tools Installation:** Installs `libvirt`, `virt-install`, `bridge-utils` and enables `libvirtd` and `qemu-guest-agent`. Adds the admin user to `libvirt` and `kvm` groups.
9.  **Disable Cloud-Init:** Disables the `cloud-init` service to prevent it from running on subsequent boots.
10. **Reboot:** Reboots the VM to apply all changes.

### Role-Specific Cloud-Init Steps:

*   **Puppet Server (`puppet.tf`):** Installs `puppetserver`, configures it (certname, server, environment, runinterval), sets up autosigning (`autosign = true`), and opens firewall ports (8140, 443, 8081). Also installs the `puppet-agent` locally.
*   **FreeIPA Server (`freeipa.tf`):** Installs `ipa-server`, `ipa-server-dns`, runs `ipa-server-install` (using `var.freeipa_password`, hardcoded domain/realm, enables DNS), and opens necessary firewall ports.
*   **Prometheus Server (`prometheus.tf`):** Downloads Prometheus binaries (v2.43.0), creates user/directories, sets up systemd service, copies default config/console files, and opens firewall ports (9090, 9093). *Note: Scrape target configuration appears commented out.*
*   **Grafana Server (`grafana.tf`):** Adds the Grafana YUM repository, installs the `grafana` package, opens firewall port 3000, and enables the `grafana-server` service.
*   **OpenVPN Server (`openvpn.tf`):** Enables IP forwarding (`net.ipv4.ip_forward = 1`) and configures firewall masquerading. *Note: Actual OpenVPN server installation is not performed here.*

## 4. Puppet Configuration (`provisioning/puppet/`)

Puppet is used for ongoing configuration management after the initial Cloud-Init bootstrap.

### Environment Structure

The configuration resides within the `production` environment (`provisioning/puppet/code/environments/production/`). Key components include:

*   `manifests/`: Contains the main `site.pp` manifest.
*   `modules/`: Contains custom and downloaded Puppet modules.
*   `hiera.yaml`: Defines the Hiera hierarchy for data lookups.
*   `data/`: Contains Hiera data files (e.g., `common.yaml`).

### Modules (`modules/`)

The following modules were identified:

*   **Custom:** `bashrc`, `common_packages`, `custom_facts`, `docker_install`, `haproxy`, `htop`, `kubernetes`, `node_exporter`, `profile_setup`. (Purpose inferred from names).
*   **Standard/Downloaded:** `firewalld`, `stdlib`.

### Site Manifest (`manifests/site.pp`)

This file defines which classes are applied to nodes:

*   **Global:** Creates a `testgroup` group resource.
*   **`node default`:** Applies to any node not matching a more specific definition. Includes:
    *   `custom_facts`
    *   `common_packages`
    *   `profile_setup`
    *   `node_exporter` (Potentially overlaps with Cloud-Init installation)
*   **Specific Nodes (by hostname pattern):**
    *   `docker*.grasslake.local`: Default modules + `docker_install`.
    *   `kmaster*.grasslake.local`: Default modules + `kubernetes::master`.
    *   `knode*.grasslake.local`: Default modules + `kubernetes::worker`.
    *   `haproxy*.grasslake.local`: Default modules + `haproxy::config`, `haproxy::install`.

### Hiera Data

Hiera (`hiera.yaml`, `data/common.yaml`) is likely used to provide parameters to the Puppet classes, allowing for customization without modifying the module code directly. The specific contents of `common.yaml` were not reviewed.

## 5. Identified Discrepancies & Considerations

*   **Domain Name Mismatch:** Terraform configurations use `${var.domain_name}` (likely defaulting to or intended as `test.lab` based on Cloud-Init scripts and variable descriptions) for VM hostnames. However, `site.pp` uses explicit `grasslake.local` domain names in its node definitions. This mismatch will prevent Puppet from applying the specific configurations for Kubernetes and HAProxy nodes unless the Terraform `domain_name` variable is set to `grasslake.local` or the `site.pp` node definitions are updated to use the correct domain and hostname patterns (e.g., `/^kcontrol\d+\.test\.lab$/`).
*   **Missing Puppet Node Definitions:** The `site.pp` manifest lacks specific `node` blocks for `puppet`, `freeipa`, `prometheus`, `grafana`, and `openvpn` servers. These nodes will receive only the classes defined in the `node default` block. The mechanism for applying their core application configurations (e.g., Prometheus scrape targets, Grafana data sources, OpenVPN server setup, Puppet server tuning) is not defined within the reviewed `site.pp` and might be handled by modules included in `node default` (less likely for such specific configs), missing entirely, or intended to be done manually.
*   **Potentially Outdated `site.pp`:** The `site.pp` includes node definitions for `docker*.grasslake.local`, but the reviewed Terraform files do not contain resources to create these specific VMs. This section of `site.pp` might be outdated or relate to unreviewed infrastructure definitions.
*   **Hardcoded Values:** The Cloud-Init scripts consistently use hardcoded values for the FreeIPA domain (`test.lab`), realm (`TEST.LAB`), and the principal/password (`admin`/`testlabs`) when running `ipa-client-install`. These should ideally be parameterized using Terraform variables for better security and flexibility. Similarly, the Puppet Server FQDN (`puppet.test.lab`) is hardcoded in the `nc` check within Cloud-Init scripts.