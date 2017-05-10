class site::nfs_server (
  Boolean          $kerberos     = simplib::lookup('simp_options::kerberos', { 'default_value' => false }),
  Simplib::Netlist $trusted_nets = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
){
  include '::nfs'

  if $kerberos {
    $security = 'krb5p'
  } else {
    $security = 'sys'
  }

  $nfs_security = $kerberos ? { true => 'krb5p', false => 'sys' }

  file { '/var/nfs_share':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  nfs::server::export { 'nfs4_root':
    clients     => $trusted_nets,
    export_path => '/var/nfs_share',
    sec         => [$nfs_security],
    require     => File['/var/nfs_share']
  }
#  iptables::listen::tcp_stateful { 'My_nfs_client_tcp_ports':
#        trusted_nets => $trusted_nets,
#        dports       => [2049,111]
#  }
#  iptables::listen::udp { 'My_nfs_client_udp_ports':
#        trusted_nets => $trusted_nets,
#        dports       => [2049,111]
#  }

}
