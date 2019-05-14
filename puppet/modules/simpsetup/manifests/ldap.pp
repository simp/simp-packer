#  This sets up 5 users and 3 groups in LDAP:
#  * `user1` and `user2` in the `Users` group.
#  * `admin1` and `admin2` in the `Admin` group
#  * `auditor1`  in the `security` group
#
# @param    $domain The domain name.
#              It will assume the basedn is of the form
#              dc=my,dc=domain,dc=name
# @param    $password The password for the root user in LDAP.
class simpsetup::ldap(
  String      $domain    = $simpsetup::domain,
  String      $password  = 'P@ssw0rdP@ssw0rd',
  String      $env       = $simpsetup::environment
) {

  $_domain = split($domain, '\.')
  $domain_dn = $_domain.join(',dc=')
  $basedn = "dc=${domain_dn}"

  file {  '/tmp/add.ldif':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  epp('simpsetup/ldifs/add.ldif.epp')
  }
  file {  '/tmp/mod.ldif':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  epp('simpsetup/ldifs/mod.ldif.epp')
  }

  Exec['packer_addto_ldap'] -> Exec['packer_mod_ldap']

  exec { 'packer_addto_ldap':
    command => "/usr/bin/ldapadd -Z -x -w ${password} -D \"cn=LDAPAdmin,OU=People,${basedn}\" -f /tmp/add.ldif",
    cwd     => "/var/simp/environments/${env}/FakeCA",
    require => File['/tmp/add.ldif']
  }

  exec { 'packer_mod_ldap':
    command => "/usr/bin/ldapmodify -Z -x -w ${password} -D \"cn=LDAPAdmin,OU=People,${basedn}\" -f /tmp/mod.ldif",
    cwd     => "/var/simp/environments/${env}/FakeCA",
    require => [File['/tmp/mod.ldif'],Exec['packer_addto_ldap']]
  }

}
