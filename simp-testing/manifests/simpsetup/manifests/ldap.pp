#  This sets up 4 users and 2 groups in LDAP:
#  user1 and user2 in the Users group.
#  admin1 and admin 2 in the Admin group
#
# @param    $domain The domain name.
#              It will assume the basedn is of the form
#              dc=my,dc=domain,dc=name
# @param    $password The password for the root user
#              in LDAP.
class simpsetup::ldap(
  String      $domain    = $simpsetup::domain,
  String      $password  = 'P@ssw0rdP@ssw0rd'
) {

  $_domain = split($domain, '\.')
  $basedn = "dc=${ $_domain.join(',dc=')}"

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
    cwd     => '/var/simp/environments/simp/FakeCA',
    require => File['/tmp/add.ldif']
  }

  exec { 'packer_mod_ldap':
    command => "/usr/bin/ldapmodify -Z -x -w ${password} -D \"cn=LDAPAdmin,OU=People,${basedn}\" -f /tmp/mod.ldif",
    cwd     => '/var/simp/environments/simp/FakeCA',
    require => File['/tmp/mod.ldif']
  }

}
