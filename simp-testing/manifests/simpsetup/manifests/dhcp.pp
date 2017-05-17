class simpsetup::dhcp {

  $rsync_dir = '/var/simp/environments/simp/rsync/CentOS/Global/dhcp'
  $fwdaddr = ($simpsetup::ipaddress.split('.'))[0,3].join('.')

  case $facts['os']['release']['major'] {
    '7':     { $iface='enp0s8' }
    default: { $iface='eth1'}
  }
  $macprefix = ($facts['networking']['interfaces'][$iface]['mac'].split(':'))[0,5].join(':')

  concat { 'rsync-dhcpd.conf':
    ensure => true,
    path   => "${rsync_dir}/dhcpd.conf",
    owner  => 'root',
    group  => 'dhcpd',
    mode   => '0640',
    order  => 'numeric'
  }

  concat::fragment { 'dhcp-header':
    target  => 'rsync-dhcpd.conf',
    order   => 0,
    content => template('simpsetup/rsync/dhcp/dhcp-header.epp'),
  }

  concat::fragment { 'dhcp-data':
    target  => 'rsync-dhcpd.conf',
    order   => 1,
    content => template('simpsetup/rsync/dhcp/dhcp-data.epp'),
  }

}

