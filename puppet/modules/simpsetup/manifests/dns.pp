#  Sets up the dns server files in rsync based on
#  @param $domain       The domain name
#  @param $relver       The  OS release.  The network interfaces
#                        are different based on the OS release
#  @param $ipaddress    The puppetip address
#  @param $dnsserver    The fqdn of the dns server
#  @param $allowed_nets CIDR address of networks allowed
#                        to query DNS.
class simpsetup::dns(
  String              $domain = $simpsetup::domain,
  String              $dnsserver = $simpsetup::dnsserver,
  String              $ipaddress = $simpsetup::ipaddress,
  String              $relver = $simpsetup::relver,
  String              $allowed_nets = $simpsetup::allowed_nets,
  String              $env = $simpsetup::environment
){

  $_ip = split($ipaddress,'\.')
  $fwdaddr = join($_ip[0,3],'.')
  $lastip  = $_ip[3]
  $revaddr = join(reverse($_ip[0,3]),'.')
  $dns_rsync_dir = "/var/simp/environments/${env}/rsync/CentOS/${relver}/bind_dns/default/named"

  file { "${dns_rsync_dir}/etc/zones/${domain}":
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => epp('simpsetup/rsync/dns/zones.epp')
  }

  file { "${dns_rsync_dir}/etc/named.conf":
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => epp("simpsetup/rsync/dns/${relver}/named_conf.epp")
  }

  concat { 'dns-forward':
    path  => "${dns_rsync_dir}/var/named/forward/${domain}.db",
    owner => 'root',
    group => 'named',
    mode  => '0640',
    order => 'numeric',
  }

  concat { 'dns-reverse':
    path  => "${dns_rsync_dir}/var/named/reverse/${revaddr}.db",
    owner => 'root',
    group => 'named',
    mode  => '0640',
    order => 'numeric',
  }

  concat::fragment { 'dsn-forward-header':
    target  => 'dns-forward',
    order   => 0,
    content => epp('simpsetup/rsync/dns/forward-header.epp'),
  }

  concat::fragment { 'dsn-revers-header':
    target  => 'dns-reverse',
    order   => 0,
    content => epp('simpsetup/rsync/dns/reverse-header.epp'),
  }

  concat::fragment { 'dsn-forward-data':
    target  => 'dns-forward',
    order   => 1,
    content => epp('simpsetup/rsync/dns/forward-data.epp'),
  }

  concat::fragment { 'dsn-revers-data':
    target  => 'dns-reverse',
    order   => 1,
    content => epp('simpsetup/rsync/dns/reverse-data.epp'),
  }

}
