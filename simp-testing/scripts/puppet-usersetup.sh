#!/bin/sh
#  Because this script is used before the reboot the path is not
#  set for simp user so I add this to the end
#  incase it is Puppet 4.0
export PATH="$PATH:/opt/puppetlabs/bin"

pupenvdir=`puppet config print environmentpath`

echo "The puppet environment directory is: $pupenvdir"

if [ ! -d ${pupenvdir}/simp/modules/site/manifests ]; then
   mkdir -p ${pupenvdir}/simp/modules/site/manifests
fi

cat << EOF > ${pupenvdir}/simp/modules/site/manifests/vagrant.pp
# site-specific configuration
#
# in this instance, it is just some tweaks to make sure simp in vagrant runs well
class site::vagrant {
  pam::access::rule { 'vagrant':
    permission => '+',
    users      => ['(vagrant)'],
    origins    => ['ALL'],
  }
  sudo::user_specification { 'vagrant_sudosh':
    user_list => ['vagrant'],
    host_list => ['ALL'],
    cmnd      => ['/usr/bin/sudosh'],
    passwd    => false,
  }
  sudo::user_specification { 'simp_sudosh':
    user_list => ['simp'],
    host_list => ['ALL'],
    cmnd      => ['ALL'],
    passwd    => false,
  }
  sudo::default_entry { 'simp_default_notty':
    content => ['!env_reset, !requiretty'],
    target => 'simp',
    def_type => 'user'
  }
  sudo::user_specification { 'vagrant_ssh':
    user_list => ['vagrant'],
    passwd    => false,
    cmnd      => ['ALL']
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

chown root:puppet ${pupenvdir}/simp/hieradata/default.yaml
chmod g+rX ${pupenvdir}/simp/hieradata/default.yaml
chown -R root:puppet ${pupenvdir}/simp/modules/site
chmod -R g+rX ${pupenvdir}/simp/modules/site/manifests

puppet apply -e "include site::vagrant"

