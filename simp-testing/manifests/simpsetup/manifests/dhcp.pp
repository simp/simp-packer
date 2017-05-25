class simpsetup::dhcp (
  String      $ksip      = $simpsetup::ipaddress,
  String      $dnsip     = $simpsetup::ipaddress,
  String      $domain    = $simpsetup::domain,
  String      $fwdaddr   = $simpsetup::fwdaddr,
){

  $rsync_dir = '/var/simp/environments/simp/rsync/CentOS/Global/dhcpd'

  case $facts['os']['release']['major'] {
    '7':     { $iface='enp0s8' }
    default: { $iface='eth1'}
  }
  $_macprefix = split($facts['networking']['interfaces'][$iface]['mac'],':')
  $macprefix = $_macprefix[0,5].join(':')


  concat { 'rsync-dhcpd.conf':
    path   => "${rsync_dir}/dhcpd.conf",
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    order  => 'numeric'
  }

  concat::fragment { 'dhcp-header':
    target  => 'rsync-dhcpd.conf',
    order   => 0,
    content => epp('simpsetup/rsync/dhcp/dhcp-header.epp'),
  }

  concat::fragment { 'dhcp-data':
    target  => 'rsync-dhcpd.conf',
    order   => 1,
    content => epp('simpsetup/rsync/dhcp/dhcp-data.epp'),
  }

}

