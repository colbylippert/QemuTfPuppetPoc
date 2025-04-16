class common_packages {

  notice('Install bind-utils')
  package { 'bind-utils':
    ensure => installed,
  }

  notice('Install net-tools')
  package { 'net-tools':
    ensure => installed,
  }

  notice('Install mtr')
  package { 'mtr':
    ensure => installed,
  }

  notice('Install nano')
  package { 'nano':
    ensure => installed,
  }

  notice('Install ruby')
  package { 'ruby':
    ensure => installed,
  }

  notice('Install wget')
  package { 'wget':
    ensure => installed,
 }

  notice('Install telnet')
  package { 'telnet':
    ensure => installed,
  }

}
