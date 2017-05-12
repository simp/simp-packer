# Note the difference in the `extra` arguments here.
class site::tftpboot {
  include '::tftpboot'

  tftpboot::linux_model { 'el7_x86_64':
    kernel => 'centos-7-x86_64/vmlinuz',
    initrd => 'centos-7-x86_64/initrd.img',
    ks     => "https://192.168.122.7/ks/pupclient_x86_64.cfg",
    extra  => "inst.noverifyssl ksdevice=bootif\nipappend 2"
  }

  tftpboot::assign_host { 'default': model => 'el7_x86_64' }
}

