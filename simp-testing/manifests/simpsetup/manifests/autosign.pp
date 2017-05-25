class simpsetup::autosign(
  String     $domain = $simpsetup::domain
){
#
#  This will set up puppet autosign to sign off any
#  host in the domain.

  file { "$facts['puppet_confdir']/autosign.conf":
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    content => inline_epp("*.<%= $simpsetup::autosign::domain %>")
  }

}
