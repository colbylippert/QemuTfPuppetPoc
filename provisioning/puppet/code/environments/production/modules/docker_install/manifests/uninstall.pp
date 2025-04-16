class docker_install::uninstall {
  # Ensure Docker services are stopped and disabled
  service { 'docker':
    ensure => stopped,
    enable => false,
    before => Package['docker-ce', 'docker-ce-cli', 'containerd.io'],
  }

  # Remove Docker packages
  package { ['docker-ce', 'docker-ce-cli', 'containerd.io']:
    ensure => purged,
  }

  # Optionally remove Docker repository and configuration files
  file { ['/etc/docker']:
    ensure  => absent,
    recurse => true,
    before  => Package['docker-ce'],
  }

  file { '/etc/yum.repos.d/docker-ce.repo':
    ensure => absent,
  }
}
