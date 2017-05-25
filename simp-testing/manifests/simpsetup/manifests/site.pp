class simpsetup::site (
  String    sitedir  = '/etc/puppetlabs/simp/modules/site/manifests'
){

  $site_man_dir = "/etc/puppetlabs/simp/modules/site/manifests']"
  file { "${site_man_dir}/tftpboot.pp"
    ensure => file,
    owner  => root,
    group  => puppet,
    mode   => '0640',
    source => 'puppet:///modules/simpsetup/site_manifests/tftpboot.pp'
  }
  file { "${site_man_dir}/workstations.pp"
    ensure => file,
    owner  => root,
    group  => puppet,
    mode   => '0640',
    source => 'puppet:///modules/simpsetup/site_manifests/workstations.pp'
  }

}
