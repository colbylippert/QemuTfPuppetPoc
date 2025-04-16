class kubernetes::worker {
  require kubernetes

  # Join the Kubernetes cluster
  exec { 'kubeadm join':
    path    => ['/bin', '/usr/bin'],
    command => 'kubeadm join --token <your_token> <master_ip>:6443',
    unless  => '/usr/bin/test -f /etc/kubernetes/kubelet.conf',
    require => Service['kubelet'],
  }
}
