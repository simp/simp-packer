class simpsetup::dhcp {

  $rsync_dir = "/var/simp/environments/simp/rsync/CentOS/Global/dhcp"

  concat { "rsync-dhcpd.conf":
    ensure  => $ensure,
    path    => "${rsync_dir}/dhcpd.conf",
    owner   => 'root',
    group   => 'dhcpd',
    mode    => '0640',
    order   => 'numeric',
  }

  concat::fragment { "dhcp-header":
    target  => "rsync-dhcpd.conf",
    order   => 0,
    content => template('simpsetup/rsync/dhcp/dhcp-header.epp'),
  }

  concat::fragment { "dhcp-data":
    target  => "rsync-dhcpd.conf",
    order   => 1,
    content => template('simpsetup/rsync/dhcp/dhcp-data.epp'),
  }

}

