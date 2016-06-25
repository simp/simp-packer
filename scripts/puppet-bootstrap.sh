#!/bin/sh

cat << EOF > /etc/puppet/environments/simp/modules/site/manifests/vagrant.pp
# site-specific configuration
#
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
  sudo::user_specification { 'vagrant_ssh':
    user_list => 'vagrant',
    passwd    => false,
    cmnd      => 'ALL'
  }
  # network::add_eth { 'enp0s3':
  #   bootproto    => 'none',
  #   gateway      => '10.0.2.2',
  #   ipaddr       => '10.0.2.15',
  #   netmask      => '255.255.255.0',
  #   onboot       => 'yes',
  # }
  service { 'vboxadd': }
  service { 'vboxadd-service': }
}
EOF

cat << EOF > /etc/puppet/environments/simp/hieradata/default.yaml
---
classes:
  - 'site::vagrant'

# remove requiretty from defaults
simplib::sudoers::default_entry:
  - 'listpw=all'
  - 'syslog=authpriv'
  - '!root_sudo'
  - '!umask'
  - 'env_reset'
  - 'secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  - 'env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"'

# enable root login over ssh
ssh::server::conf::permitrootlogin: true
ssh::server::conf::authorizedkeysfile : ".ssh/authorized_keys"
EOF

