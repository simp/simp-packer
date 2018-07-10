# This enters *.<domain>  in the autosign file so all
# the certs get signed off automatically when new systems
# connect
#
# @param $domain    The doamin name.
#
class simpsetup::autosign(
  String     $domain = $simpsetup::domain
){
#
#  This will set up puppet autosign to sign off any
#  host in the domain.

#  file { "$facts['puppet_confdir']/autosign.conf":
  file { '/etc/puppetlabs/puppet/autosign.conf':
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    content => "*.${domain}"
  }

}
