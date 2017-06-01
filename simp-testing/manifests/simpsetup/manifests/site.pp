class simpsetup::site (
  String    $sitedir  = '/etc/puppetlabs/code/environments/simp/modules/site/manifests'
){

  file { "${sitedir}/tftpboot.pp":
    ensure  => file,
    owner   => root,
    group   => puppet,
    mode    => '0640',
    content => template('simpsetup/site/manifests/tftpboot.pp.erb')
  }
  file { "${sitedir}/workstations.pp":
    ensure  => file,
    owner   => root,
    group   => puppet,
    mode    => '0640',
    content => template('simpsetup/site/manifests/workstations.pp.erb')
  }

}
