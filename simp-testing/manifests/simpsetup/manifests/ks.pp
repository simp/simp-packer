class simpsetup::ks {

  $fips = $facts['fips_enabled']
  $linuxdist = $facts['os']['name']
  $ksdir = '/var/www/ks'
  $ksip = $facts['networking']['ip']

  file { "${ksdir}/pupclient_x86_64.cfg":
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => epp('simpsetup/ks/pupclient_x86_64.cfg.epp')
  }
}
