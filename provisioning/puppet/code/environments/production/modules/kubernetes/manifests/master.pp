class kubernetes::master {
  require kubernetes

  # Disable swap
  exec { 'swapoff -a':
    command => '/sbin/swapoff -a',
    path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'],
  }

  # Enable IP forwarding
  exec { 'enable-ip-forwarding':
    command => '/sbin/sysctl -w net.ipv4.ip_forward=1',
    unless  => '/usr/bin/grep -q "^net.ipv4.ip_forward = 1" /etc/sysctl.conf',
    path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'],
    before  => Exec['kubeadm init'],
  }

  # Add containerd repository
  file { '/etc/yum.repos.d/containerd.repo':
    ensure  => file,
    content => "[containerd]\nname=containerd repository\nbaseurl=https://download.docker.com/linux/centos/9/x86_64/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg\n",
    before  => Package['containerd'],
  }

  # Ensure containerd is running
  package { 'containerd':
    ensure  => installed,
    require => File['/etc/yum.repos.d/containerd.repo'],
  }

  file { '/etc/containerd/config.toml':
    ensure  => file,
    content => template('kubernetes/containerd_config.toml.erb'),
    require => Package['containerd'],
    notify  => Service['containerd'],
  }

  service { 'containerd':
    ensure  => running,
    enable  => true,
    require => Package['containerd'],
    before  => Exec['kubeadm init'],
  }

  # Ensure required networking tools are installed
  package { ['conntrack-tools', 'iproute', 'iptables', 'ebtables', 'ethtool', 'iproute-tc']:
    ensure => installed,
  }

  # Initialize the Kubernetes cluster
  exec { 'kubeadm init':
    command => '/usr/bin/kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=k8s-api.grasslake.local:6443 --upload-certs',
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    unless  => '/usr/bin/test -f /etc/kubernetes/admin.conf',
    require => [Service['kubelet'], Exec['swapoff -a'], Exec['enable-ip-forwarding'], Service['containerd'], Package['conntrack-tools'], Package['iproute'], Package['iptables'], Package['ebtables'], Package['ethtool'], Package['iproute-tc']],
    notify  => Exec['kubectl apply'],
  }

  # Apply the Weave Net CNI plugin
  exec { 'kubectl apply':
    command     => 'kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d \'\n\')',
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
    subscribe   => Exec['kubeadm init'],
  }

  # Open Kubernetes API Server port
  firewalld_port { 'Kubernetes API Server':
    ensure   => 'present',
    zone     => 'public',
    protocol => 'tcp',
    port     => 6443,
  }

  # Open Kubelet port
  firewalld_port { 'Kubelet':
    ensure   => 'present',
    zone     => 'public',
    protocol => 'tcp',
    port     => 10250,
  }
}
