class htop {
 notice('Install htop')
  # Ensure the EPEL release package is installed
  package { 'epel-release':
    ensure => installed,
    before => Package['htop'],  # Ensures EPEL is set up before htop installation
  }

  # Ensure htop is installed
  package { 'htop':
    ensure => installed,
    require => Package['epel-release'],  # Makes sure EPEL is installed first
  }
}
