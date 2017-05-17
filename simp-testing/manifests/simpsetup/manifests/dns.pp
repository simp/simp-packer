class simpsetup::dns(
  String              $domain = $simpsetup::domain,
  String              $dnsserver = $simpsetup::dnsserver,
  String              $ipaddress = $simpsetup::ipaddress,
  String              $relver = $simpsetup::relver,
  String              $allowed_nets = $simpsetup::allowed_nets
){

  $revaddr = (($ipaddress.split('.'))[0,3].reverse).join('.')
  $fwdaddr = ($ipaddress.split('.'))[0,3].join('.')
  $dns_rsync_dir = "/var/simp/environments/simp/rsync/CentOS/${relver}/bind_dns/default/named"

  file { "${dns_rsync_dir}/etc/zones/${domain}":
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template('simpsetup/rsync/dns/zones.epp')
  }

  file { "${dns_rsync_dir}/etc/named.conf":
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template("simpsetup/rsync/dns/${relver}/named_conf.epp")
  }

  concat { 'dns-forward':
    ensure => true,
    path   => "${dns_rsync_dir}/var/named/forward/${domain}.db",
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    order  => 'numeric',
  }

  concat { 'dns-reverse':
    ensure => true,
    path   => "${dns_rsync_dir}/var/named/reverse/${revaddr}.db",
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    order  => 'numeric',
  }

  concat::fragment { 'dsn-forward-header':
    target  => 'dns-forward',
    order   => 0,
    content => template('simpsetup/rsync/dns/forward-header.epp'),
  }

  concat::fragment { 'dsn-revers-header':
    target  => 'dns-reverse',
    order   => 0,
    content => template('simpsetup/rsyn/dns/reverse-header.epp'),
  }

  concat::fragment { 'dsn-forward-data':
    target  => 'dns-forward',
    order   => 1,
    content => template('simpsetup/rsync/dns/forward-data.epp'),
  }

  concat::fragment { 'dsn-revers-data':
    target  => 'dns-reverse',
    order   => 1,
    content => template('simpsetup/rsync/dns/reverse-data.epp'),
  }

}
