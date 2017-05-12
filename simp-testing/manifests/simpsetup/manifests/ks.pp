class simpsetup::ks (
  Boolean    $fips  = $simpsetup::fips
) {

  linuxdist = $facts['os']['name']
  ksdir = '/var/www/ks'

  file { "${ksdir}/pupclient_x86_64.cfg":
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => template('simpsetup/ks/pupclient_x86_64.cfg')
  }
}
