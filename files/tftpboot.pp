class site::tftpboot {
  include 'tftpboot'

  tftpboot::linux_model { 'centos-7-x86_64':
    kernel => 'centos-7-x86_64/vmlinuz',
    initrd => 'centos-7-x86_64/initrd.img',
    ks     => "http://puppet.test.net/ks/pupclient_x86_64.cfg",
    extra  => "ksdevice=bootif\nipappend 2"
  }

  tftpboot::assign_host { 'default': model => 'centos-7-x86_64' }
}
