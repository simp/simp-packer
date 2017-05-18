class simpsetup::autosign {
#
#  This will set up puppet autosign to sign off any
#  host in the domain.

  file { "$facts['puppet_confdir']/auth.conf.simp":
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    content => inline_epp("*.<%= $simpsetup::domain %>")
  }

}
