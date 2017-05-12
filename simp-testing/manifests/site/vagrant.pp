# in this instance, it is just some treaks to make sure simp in vagrant runs well
class site::vagrant {
  pam::access::manage { 'vagrant':
    permission => '+',
    users      => '(vagrant)',
    origins    => ['ALL'],
  }
  sudo::user_specification { 'vagrant_sudosh':
    user_list => 'vagrant',
    host_list => 'ALL',
    runas     => 'ALL',
    cmnd      => '/usr/bin/sudosh',
    passwd    => false,
  }
  sudo::user_specification { 'simp_sudosh':
    user_list => 'simp',
    host_list => 'ALL',
    runas     => 'ALL',
    cmnd      => 'ALL',
    passwd    => false,
  }
  sudo::default_entry { 'simp_default_notty':
    content => ['!env_reset, !requiretty'],
    target => 'simp',
    def_type => 'user'
  }

  sudo::user_specification { 'vagrant_ssh':
    user_list => 'vagrant',
    passwd    => false,
    cmnd      => 'ALL'
  }
  service { 'vboxadd': }
  service { 'vboxadd-service': }
}
