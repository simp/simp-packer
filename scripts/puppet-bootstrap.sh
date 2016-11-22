#!/bin/sh

# enable fips-compliant checksum hashes
sudo cp /var/local/simp/files/puppet.conf /etc/puppet/puppet.conf
sudo chown :puppet /etc/puppet/puppet.conf
sudo chmod 640 /etc/puppet/puppet.conf

mv /etc/puppet/environments/simp/hieradata/hosts/puppet.your.domain.yaml /etc/puppet/environments/simp/hieradata/hosts/server01.simp.test.yaml

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
  sudo::default_entry { 'vagrant':
    def_type => 'user',
    target   => 'vagrant',
    content  => ['!requiretty'],
  }
  network::add_eth { 'enp0s3':
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

cat << EOF > /etc/puppet/environments/simp/hieradata/default.yaml
---
classes:
  - 'site::vagrant'

simplib::resolv::option_rotate: false
EOF

sed "/^\$hostgroup = 'default'$/d" /etc/puppet/environments/simp/manifests/site.pp
sed "/^hiera_include('classes')$/d" /etc/puppet/environments/simp/manifests/site.pp

cat << EOF > /etc/puppet/environments/simp/manifests/site.pp
\$hostgroup = $::trusted['certname'] ? {
  /^client[[:digit:]]{2}\.simp\.test/ => 'clients',
  default                             => 'default',
}

node default {
  hiera_include('classes', [])
}
EOF

cat << EOF > /etc/puppet/environments/simp/hieradata/hosts/server01.simp.test.yaml
---
classes:
  - 'site::server'
EOF

cat << EOF > /etc/puppet/environments/simp/modules/site/manifests/server.pp
class 'site::server' {
  \$interfaces_array = split($::interfaces, ',')

  if member(\$interfaces_array, 'enp0s8') {
    network::add_eth { 'enp0s8':
      bootproto => 'none',
      ipaddr    => '192.168.33.10',
      netmask   => '255.255.255.0',
      onboot    => 'yes',
    }
  }
}
EOF

cat << EOF > /etc/puppet/environments/simp/hieradata/hostgroups/clients.yaml
---
classes:
  - 'site::clients'
EOF

cat << EOF > /etc/puppet/environments/simp/modules/site/manifests/clients.pp
class 'site::clients' {
  network::add_eth { 'enp0s8':
    bootproto => 'none',
    ipaddr    => "\${::ipaddress_enp0s8}",
    netmask   => "\${::netmask_enp0s8}",
    onboot    => 'yes',
  }
}
EOF

# add tftpboot class to default puppetserver hierafile
echo "  - 'site::tftpboot'" >> /etc/puppet/environments/simp/hieradata/hosts/server01.simp.test.yaml

# # add vagrant user spec to localusers to ensure presence on all hosts
# echo '!*,vagrant,1778,1778,/home/vagrant,$6$rounds=10000$bfakeujk$TZYotmPja3t95YXaUT2Np7cFl9TcBZML0y9e3CW6QU6EuvOFL805TAJqxqcmYJDTOO/H.PMZt54D/LaZ3UrHC.' >> /etc/puppet/environments/simp/localusers

# # generate client certs for kickstarted client
# echo client01.simp.test > /etc/puppet/environments/simp/FakeCA/togen
# echo server01.simp.test > /etc/puppet/environments/simp/FakeCA/togen
# cd /etc/puppet/environments/simp/FakeCA/
# ./gencerts_nopass.sh
