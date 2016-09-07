| question | answer for this testenv |
| -------: | ------------------- |
| use_fips | yes |
| network::interface | enp0s3 |
| network::setup_nic | yes |
| dhcp | static |
| hostname | server01.simp.test |
| ipaddress | 10.0.2.15 |
| netmask | 255.255.255.0 |
| gateway | 10.0.2.2 |
| dns::servers | 192.168.22.10 8.8.8.8 |
| dns::search | simp.test |
| client_nets | 10.0.2.0/24 192.168.33.10/24 |
| ntpd::servers | 0.pool.ntp.org 1.pool.ntp.org |
| log_servers | server01.simp.test |
| failover_log_servers |  |
| simp::yum::servers | %{hiera('puppet::server')} |
| use_auditd | yes |
| use_iptables | yes |
| simplib::runlevel | 3 |
| selinux::ensure | enforcing |
| set_grub_password | yes |
| is_master_yum_server | yes |
| puppet::server | server01.simp.test |
| puppet::server::ip | 192.168.33.10 |
| puppet::ca | server01.simp.test |
| puppet::ca_port | 8141 |
| use_ldap | yes |
| ldap::base_dn | dc=simp,dc=test |
| ldap::bind_dn | cn=hostAuth,ou=Hosts,%{hiera('ldap::base_dn')} |
| ldap::sync_dn | cn=LDAPSync,ou=Hosts,%{hiera('ldap::base_dn')} |
| ldap::root_dn | cn=LDAPAdmin,ou=People,%{hiera('ldap::base_dn')} |
| ldap::master | ldap://server01.simp.test |
| ldap::uri | ldap://server01.simp.test |
| rsync::base | /var/simp/rsync/%{::operatingsystem}/%{::lsbmajdistrelease} |
