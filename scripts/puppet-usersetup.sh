#!/bin/sh
#  Because this script is used before the reboot the path is not
#  set for simp user so I add this to the end
#  incase it is Puppet 4.0
export PATH="${PATH}:/opt/puppetlabs/bin"

pupenvdir=$(puppet config print environmentpath)

echo "The puppet environment directory is: $pupenvdir"

if [ ! -d "${pupenvdir}/simp/modules/site/manifests" ]; then
   mkdir -p "${pupenvdir}/simp/modules/site/manifests"
fi

cat << EOF > "${pupenvdir}/simp/modules/site/manifests/vagrant.pp"
# site-specific configuration
#
# in this instance, it is just some tweaks to make sure simp in vagrant runs well
class site::vagrant {
  pam::access::rule { 'vagrant_simp':
    permission => '+',
    users      => ['vagrant','simp'],
    origins    => ['ALL'],
  }

  # The vagrant user needs Password-less Sudo
  #
  #   https://www.vagrantup.com/docs/boxes/base.html#password-less-sudo
  #
  sudo::user_specification { 'vagrant_passwordless_sudo':
    user_list => ['vagrant'],
    host_list => ['ALL'],
    cmnd      => ['ALL'],
    passwd    => false,
  }

  sudo::user_specification { 'simp_sudo':
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

  sudo::default_entry { 'vagrant_default_notty':
    content => ['!env_reset, !requiretty'],
    target => 'vagrant',
    def_type => 'user'
  }

  # Make vboxadd* services known to svckill
  service { 'vboxadd': }
  service { 'vboxadd-service': }
}
EOF

cat << EOF > "${pupenvdir}/simp/hieradata/default.yaml"
---
classes:
  - 'site::vagrant'

# enable root login over ssh
ssh::server::conf::permitrootlogin: true
# change the default authorized keys file to the users local dir for vagrant
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
simplib::resolv::option_rotate: false
EOF

chown root:puppet "${pupenvdir}/simp/hieradata/default.yaml"
chmod g+rX "${pupenvdir}/simp/hieradata/default.yaml"
chown -R root:puppet "${pupenvdir}/simp/modules/site"
chmod -R g+rX "${pupenvdir}/simp/modules/site/manifests"

puppet apply -e "include site::vagrant"
