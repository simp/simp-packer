#!/bin/sh

# enable fips-compliant checksum hashes
sudo cp /var/local/simp/files/puppet.conf /etc/puppet/puppet.conf
sudo chown :puppet /etc/puppet/puppet.conf
sudo chmod 640 /etc/puppet/puppet.conf

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

# remove requiretty from defaults so vagrant can provision vm
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
ssh::server::conf::authorizedkeysfile: ".ssh/authorized_keys"

simplib::resolv::option_rotate: false
EOF

# add tftpboot class to default puppetserver hierafile
echo "  - 'site::tftpboot'" >> /etc/puppet/environments/simp/hieradata/hosts/puppet.your.domain.yaml

# # add vagrant user spec to localusers to ensure presence on all hosts
# echo '!*,vagrant,1778,1778,/home/vagrant,$6$rounds=10000$bfakeujk$TZYotmPja3t95YXaUT2Np7cFl9TcBZML0y9e3CW6QU6EuvOFL805TAJqxqcmYJDTOO/H.PMZt54D/LaZ3UrHC.' >> /etc/puppet/environments/simp/localusers

# # generate client certs for kickstarted client
# echo client.test.net > /etc/puppet/environments/simp/FakeCA/togen
# echo puppet.test.net > /etc/puppet/environments/simp/FakeCA/togen
# cd /etc/puppet/environments/simp/FakeCA/
# ./gencerts_nopass.sh
