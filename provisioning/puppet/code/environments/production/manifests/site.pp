group { 'testgroup':
  ensure => present,
  gid    => 2000,
}

node default {
  include custom_facts
  include common_packages
  include profile_setup
  include node_exporter
}

node 'docker01.grasslake.local', 'docker02.grasslake.local', 'docker03.grasslake.local' {
  include custom_facts
  include common_packages
  include profile_setup
  include node_exporter

  include docker_install
}

node 'kmaster01.grasslake.local', 'kmaster02.grasslake.local' {
  include custom_facts
  include common_packages
  include profile_setup
  include node_exporter

  include kubernetes::master
}

node 'knode01.grasslake.local', 'knode02.grasslake.local', 'knode03.grasslake.local' {
  include custom_facts
  include common_packages
  include profile_setup
  include node_exporter

  include kubernetes::worker
}

node 'haproxy01.grasslake.local', 'haproxy02.grasslake.local' {
  include custom_facts
  include common_packages
  include profile_setup
  include node_exporter
  
  include haproxy::config
  include haproxy::install
}
