class site::dnssetup
   String              $domain = $fact["domain"],
   String              $dnsserver = $facts['fqdn'],
   String              $ipaddress = $facts['ipaddress']
   String              $relver = $facts['os']['release']['major']
   Simplib::Netlist    $trusted_nets = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.01'] })
{

  $revaddr = ((ipaddress.split("."))[0,3].reverse).join(".")
  $fwdaddr = (ipaddress.split("."))[0,3].join(".")
  $dns_rsync_dir = "/var/simp/environments/simp/rsync/CentOS/${relver}/bind_dns/default/named"
  $allowed_nets = nets2cidr($trusted_nets)

  file { "${dns_rsync_dir}/etc/zones/${domain}":
     owner   => "root",
     group   => "named",
     mode    => "0640",
     content => template('site/dns/zones.epp')
  }

  file { "${dns_rsync_dir}/etc/named.conf":
     owner   => "root",
     group   => "named",
     mode    => "0640",
     content => template('site/dns/${relver}/named_conf.epp')
  }

  concat { "dns-forward":
    ensure  => $ensure,
    path    => "${dns_rsync_dir}/var/named/forward/${domain}.db",
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    order   => 'numeric',
  }

  concat { "dns-reverse":
    ensure  => $ensure,
    path    => "${dns_rsync_dir}/var/named/reverse/${revaddr}.db",
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    order   => 'numeric',
  }

  concat::fragment { "dsn-forward-header":
    target  => "dns-forward",
    order   => 0,
    content => template('site/dns/forward-header.epp'),
  }

  concat::fragment { "dsn-revers-header":
    target  => "dns-reverse",
    order   => 0,
    content => template('site/dns/reverse-header.epp'),
  }

  concat::fragment { "dsn-forward-data":
    target  => "dns-forward",
    order   => 1,
    content => template('site/dns/forward-data.epp'),
  }

  concat::fragment { "dsn-revers-data":
    target  => "dns-reverse",
    order   => 1,
    content => template('site/dns/reverse-data.epp'),
  }

}
