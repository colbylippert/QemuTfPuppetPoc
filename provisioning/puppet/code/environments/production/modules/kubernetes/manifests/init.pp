class kubernetes {
  # Ensure required packages are installed
  package { ['kubelet', 'kubeadm', 'kubectl']:
    ensure => installed,
    before => Service['kubelet'],
  }

  # Ensure kubelet service is enabled and running
  service { 'kubelet':
    ensure => 'running',
    enable => true,
  }

  # Add Kubernetes repo
  file { '/etc/yum.repos.d/kubernetes.repo':
    ensure  => file,
    content => template('kubernetes/kubernetes.repo.erb'),
    before  => Package['kubelet', 'kubeadm', 'kubectl'],
  }
}
