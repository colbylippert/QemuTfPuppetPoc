class docker_install {
  # Ensure the Docker repository is added and the package is installed
  if $facts['os']['family'] == 'RedHat' {
    # Install required package for managing repositories
    package { 'yum-utils':
      ensure => installed,
    }

    # Add the Docker repository
    exec { 'add_docker_repo':
      command => '/usr/bin/yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo',
      unless  => '/usr/bin/test -f /etc/yum.repos.d/docker-ce.repo',
      require => Package['yum-utils'],
    }

    # Install Docker Engine
    package { 'docker-ce':
      ensure => installed,
      require => Exec['add_docker_repo'],
    }

    # Ensure Docker service is enabled and running
    service { 'docker':
      ensure    => running,
      enable    => true,
      require   => Package['docker-ce'],
    }
  }
}
