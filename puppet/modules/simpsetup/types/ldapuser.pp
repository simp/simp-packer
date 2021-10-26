# LDAP user information
# sec_groups are the secondary groups the user is to be added to
type Simpsetup::LdapUser = Struct[{
  uidNumber  => Integer,
  gidNumber  => Integer,
  sec_groups => Array[String]
}]
