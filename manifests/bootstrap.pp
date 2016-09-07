$enable_named = true
$enable_dhcp  = true
$enable_ks    = true

$rsync_path  = '/var/simp/rsync/CentOS/7'
$copied_path = '/var/local/simp/files'

if $enable_dhcp {
  file { "$rsync_path/dhcpd/dhcpd.conf":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    source => "file://$copied_path/dhcpd.conf",
  }
}

if $enable_named {
  $bind_path = "$rsync_path/bind_dns/default/named"
  File {
    ensure  => file,
    mode    => '0640',
    owner   => 'root',
    group   => 'named',
    require => Package['bind'],
  }
  package { 'bind': ensure => latest }
  file { "$bind_path/etc/named.conf":
    source => "file://$copied_path/named.conf",
  }
  file { "$bind_path/etc/zones/simp.test":
    source => "file://$copied_path/simp.test",
  }
  file { "$bind_path/var/named/forward/simp.test.db":
    source => "file://$copied_path/simp.test.db",
  }
  file { "$bind_path/var/named/reverse/33.168.192.db":
    source => "file://$copied_path/33.168.192.db",
  }
}

if $enable_ks {
  file { '/var/www/ks/pupclient_x86_64.cfg':
    ensure => file,
    mode   => '0640',
    owner  => 'root',
    group  => 'apache',
    source => "file://$copied_path/pupclient_x86_64.cfg",
  }
  file { '/etc/puppet/environments/simp/modules/site/manifests/tftpboot.pp':
    ensure => file,
    mode   => '0640',
    owner  => 'root',
    group  => 'puppet',
    source => "file://$copied_path/tftpboot.pp",
  }
  file { '/etc/puppet/autosign.conf':
    ensure => file,
    mode   => '0640',
    owner  => 'root',
    group  => 'puppet',
    source => "file://$copied_path/autosign.conf",
  }
}
