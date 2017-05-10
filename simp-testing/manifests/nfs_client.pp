class site::nfs_client (
  Boolean $kerberos = simplib::lookup('simp_options::kerberos', { 'default_value' => false }),
){
  include '::nfs'

  $nfs_security = $kerberos ? { true => 'krb5p', false =>  'sys' }

  file { '/mnt/nfs':
    ensure => 'directory',
    mode => '755',
    owner => 'root',
    group => 'root'
  }

  
  if $nfs::stunnel {

    nfs::client::stunnel::v4 { '192.168.121.12:2049':
      before => Mount['/mnt/nfs']
    } 
    $_nfs_server='127.0.0.1'

  } else {
    $_nfs_server=$nfs::server
  }

  mount { "/mnt/nfs":
      ensure  => 'mounted',
      fstype  => 'nfs4',
      device  => "${_nfs_server}:/var/nfs_share",
      options => "sec=${nfs_security}",
      require => File['/mnt/nfs']
  }
 
}
