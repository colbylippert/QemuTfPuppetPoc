class haproxy::install {
  package { 'haproxy':
    ensure => installed,
  }

  package { 'policycoreutils-python-utils':
    ensure => installed,
  }

  service { 'haproxy':
    ensure     => running,
    enable     => true,
    subscribe  => File['/etc/haproxy/haproxy.cfg'],
  }
}

class haproxy::config {
  $kmaster01_ip = hiera('haproxy::kmaster01_ip')
  $kmaster02_ip = hiera('haproxy::kmaster02_ip')

  file { '/etc/haproxy/haproxy.cfg':
    ensure  => file,
    content => template('haproxy/haproxy.cfg.erb'),
    require => Package['haproxy'],
    notify  => Service['haproxy'],
  }

  # Ensure run directory exists
  file { '/run/haproxy':
    ensure  => directory,
    owner   => 'haproxy',
    group   => 'haproxy',
    mode    => '0755',
    require => Package['haproxy'],
  }

  # Ensure errors directory exists
  file { '/etc/haproxy/errors':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['haproxy'],
  }

  # Ensure error files exist
  file { '/etc/haproxy/errors/400.http':
    ensure  => file,
    content => '<html><body><h1>400 Bad Request</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/403.http':
    ensure  => file,
    content => '<html><body><h1>403 Forbidden</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/408.http':
    ensure  => file,
    content => '<html><body><h1>408 Request Timeout</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/500.http':
    ensure  => file,
    content => '<html><body><h1>500 Internal Server Error</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/502.http':
    ensure  => file,
    content => '<html><body><h1>502 Bad Gateway</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/503.http':
    ensure  => file,
    content => '<html><body><h1>503 Service Unavailable</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  file { '/etc/haproxy/errors/504.http':
    ensure  => file,
    content => '<html><body><h1>504 Gateway Timeout</h1></body></html>',
    require => File['/etc/haproxy/errors'],
  }

  # Ensure HAProxy can bind to privileged ports
  exec { 'setcap_net_bind_service':
    command => '/usr/sbin/setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/haproxy',
    unless  => '/usr/sbin/getcap /usr/sbin/haproxy | grep CAP_NET_BIND_SERVICE',
    require => Package['haproxy'],
    before  => Service['haproxy'],
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
  }

  # SELinux policy to allow HAProxy to bind to privileged ports
  file { '/tmp/haproxy_bind_port.te':
    ensure  => file,
    content => "module haproxy_bind_port 1.0;

require {
    type unreserved_port_t;
    type haproxy_t;
    class tcp_socket name_bind;
}

# Allow haproxy to bind to unreserved ports
allow haproxy_t unreserved_port_t:tcp_socket name_bind;
",
    require => Package['policycoreutils-python-utils'],
  }

  exec { 'compile_haproxy_policy':
    command => 'checkmodule -M -m -o /tmp/haproxy_bind_port.mod /tmp/haproxy_bind_port.te && semodule_package -o /tmp/haproxy_bind_port.pp -m /tmp/haproxy_bind_port.mod && semodule -i /tmp/haproxy_bind_port.pp',
    creates => '/tmp/haproxy_bind_port.pp',
    require => File['/tmp/haproxy_bind_port.te'],
    before  => Service['haproxy'],
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
  }

  # Open Kubernetes API Server port
  firewalld_port { 'Kubernetes API Server':
    ensure   => 'present',
    zone     => 'public',
    protocol => 'tcp',
    port     => 6443,
  }
}
