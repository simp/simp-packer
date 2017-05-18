class site::simp::ec2_init (

  String $username = 'ec2-user'

) {
  
  file { "/etc/ssh/local_keys/$username":
    ensure => present,
    owner  => $username,
    group  => $username,
    mode   => '0600',
    source => "/var/local/${username}/.ssh/authorized_keys"
  }

  pam::access::rule { $username:
    permission => '+',
    users      => ["(${username})"],
    origins    => ['ALL'],
    order      => 1000
  }
  
  sudo::user_specification { $username:
    user_list => ["${username}"],
    passwd    => false,
    host_list => [$facts['ec2_metadata']['hostname']],
    runas     => 'root',
    cmnd      => ['/bin/su root', '/bin/su - root']
  }
}
