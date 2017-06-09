# This will configure the files in  the kick start directory
#
#  @param  $ksdir      FQ path of the kick start directory
#  @param  $linuxdist  The linux distribution name (CentOS or RedHat)
#  @param  $ksip       The ip address of the kick start server
#  @param  $fips       Wether or not fips is enabled
class simpsetup::ks (
  Boolean     $fips = $facts['fips_enabled'],
  String      $linuxdist = $facts['os']['name'],
  String      $ksdir = '/var/www/ks',
  String      $ksip = $facts['networking']['ip']
){

  file { "${ksdir}/pupclient_x86_64.cfg":
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    content => epp('simpsetup/ks/pupclient_x86_64.cfg.epp')
  }

}
