#!/bin/sh
source /var/local/simp/scripts/functions.sh
#  Because this script is used before the reboot the path is not
#  set for simp user so I add this to the end
#  incase it is Puppet 4.0
export PATH="$PATH:/opt/puppetlabs/bin"

pupenvdir=`puppet config print | grep ^environmentpath | cut -f3 -d" "`

if [ ! -d ${pupenvdir}/simp/modules/site/manifests ]; then
   mkdir -p ${pupenvdir}/simp/modules/site/manifests
   chown puppet:root ${pupenvdir}/simp/modules/site/manifests
   chmod 750 ${pupenvdir}/simp/modules/site/manifests
fi

cat << EOF > ${pupenvdir}/simp/modules/site/manifests/vagrant.pp
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
  network::add_eth { 'SIMP_PACKER_nat_network_if':
    bootproto    => 'none',
    gateway      => '10.0.2.2',
    ipaddr       => '10.0.2.15',
    netmask      => '255.255.255.0',
    onboot       => 'yes',
  }
  service { 'vboxadd': }
  service { 'vboxadd-service': }
}
EOF

cat << EOF > ${pupenvdir}/simp/hieradata/default.yaml
---
classes:
  - 'site::vagrant'

# enable root login over ssh
ssh::server::conf::permitrootlogin: true
ssh::server::conf::authorizedkeysfile: ".ssh/authorized_keys"
simplib::resolv::option_rotate: false
EOF

# # add vagrant user spec to localusers to ensure presence on all hosts
echo '!*,vagrant,1778,1778,/home/vagrant,$6$rounds=10000$bfakeujk$TZYotmPja3t95YXaUT2Np7cFl9TcBZML0y9e3CW6QU6EuvOFL805TAJqxqcmYJDTOO/H.PMZt54D/LaZ3UrHC.' >> ${pupenvdir}/simp/localusers

# # generate client certs for kickstarted client
# echo client01.simp.test > /etc/puppet/environments/simp/FakeCA/togen
# echo server01.simp.test > /etc/puppet/environments/simp/FakeCA/togen
# cd /etc/puppet/environments/simp/FakeCA/
# ./gencerts_nopass.sh
