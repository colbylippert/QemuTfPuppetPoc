class node_exporter {
  $arch = $facts['os']['architecture']
  $version = '1.8.0'
  $download_url = "https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz"

  # Ensure wget and tar are present
  package { ['tar']:
    ensure => installed,
  }

  # Download Node Exporter
  exec { 'download-node-exporter':
    command => "/usr/bin/wget ${download_url} -O /tmp/node_exporter.tar.gz",
    creates => '/tmp/node_exporter.tar.gz',
    require => Package['wget'],
  }

  # Extract Node Exporter
  exec { 'extract-node-exporter':
    command => '/bin/tar xvfz /tmp/node_exporter.tar.gz -C /opt',
    creates => "/opt/node_exporter-${version}.linux-amd64",
    require => Exec['download-node-exporter'],
  }

  # Create a systemd service file
  file { '/etc/systemd/system/node_exporter.service':
    ensure  => file,
    content => template('node_exporter/node_exporter.service.erb'),
    require => Exec['extract-node-exporter'],
  }

  # Ensure the Node Exporter service is running
  service { 'node_exporter':
    ensure    => running,
    enable    => true,
    require   => File['/etc/systemd/system/node_exporter.service'],
    subscribe => File['/etc/systemd/system/node_exporter.service'],
  }

  # Manage Firewall Rules with Firewalld
  class { 'firewalld': }

  firewalld_port { 'Prometheus Node Exporter':
    ensure   => 'present',
    zone     => 'public',
    protocol => 'tcp',
    port => 9100,
  }
}
