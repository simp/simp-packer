# @summary Creates LDAP users and groups on an OpenLDAP server
#
# This class creates scripts and LDIF and then uses them to add/modify LDAP
# users and groups.
#
# @param $ldap_dir
#   Base location of scripts and LDIF files generated by this class
#
# @param $base_dn
#   The LDAP Base DN

# @param groups
#   Hash of group name to gidNumber
#
#   * Any other required LDAP attributes required to create a posixgroup for
#     each group will be autogenerated
#
# @param users
#   Hash of user name to user info Hash
#
#   * Info Hash contains uidNumber, gidNumber, and sec_groups
#   * sec_groups is an Array of secondary group names the user belongs to
#   * Any other required LDAP attributes required to create the user will be
#     autogenerated
#
# @param root_ldap_password
#   LDAP root password
#
# @param $user_password_hash
#   The encrypted password used to set the initial password for all users

class simpsetup::ldap::openldap(
  String                           $ldap_dir           = $simpsetup::ldap::ldap_dir,
  String                           $base_dn            = $simpsetup::ldap::base_dn,
  Hash[String,Integer]             $groups             = $simpsetup::ldap::groups,
  Hash[String,Simpsetup::LdapUser] $users              = $simpsetup::ldap::users,
  String                           $root_ldap_password = 'P@ssw0rdP@ssw0rd',
  # encrypted user password corresponds to P@asswordP@ssw0rd
  String                           $user_password_hash = "{SSHA}C1xPxt0TOL7FYx6FRIgH3PkudDhtaUcR"
) {
  assert_private()

  $_ldif_dir = "${ldap_dir}/ldifs"
  file { $_ldif_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }

  $_add_users_ldif = "${_ldif_dir}/add_test_users.ldif"
  file { $_add_users_ldif:
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  template('simpsetup/ldap/ldifs/add_test_users.ldif.erb')
  }

  $_modify_users_ldif = "${_ldif_dir}/modify_test_users.ldif"
  file { $_modify_users_ldif:
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  template('simpsetup/ldap/ldifs/modify_test_users.ldif.erb')
  }

  $_add_users_script = "${ldap_dir}/add_users_openldap.sh"
  file { $_add_users_script:
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content =>  epp('simpsetup/ldap/scripts/add_test_users_openldap.sh.epp')
  }

  exec { 'packer_add_users_to_openldap':
    command => $_add_users_script,
    cwd     => $ldap_dir,
    require => [
      File[$_add_users_ldif],
      File[$_modify_users_ldif],
      File[$_add_users_script]
    ]
  }
}
