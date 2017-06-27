# Note the difference in the `extra` arguments here.
class site::tftpboot {
  include '::tftpboot'

  case $facts['os']['release']['major'] {
  '7': { tftpboot::linux_model { 'el7_x86_64':
        kernel => 'centos-7-x86_64/vmlinuz',
        initrd => 'centos-7-x86_64/initrd.img',
        ks     => "https://${facts['ipaddress']}/ks/pupclient_x86_64.cfg",
        extra  => "inst.noverifyssl ksdevice=bootif\nipappend 2"
      }
    }
  '6': { tftpboot::linux_model { 'el6_x86_64':
        kernel => 'centos-6-x86_64/vmlinuz',
        initrd => 'centos-6-x86_64/initrd.img',
        ks     => "https://${facts['ipaddress']}/ks/pupclient_x86_64.cfg",
        extra  => "noverifyssl ksdevice=bootif\nipappend 2"
      }
    }
  default: {
     warn("${facts['os']['release']['major']} not supported for tftpboot")
    }
  }


  tftpboot::assign_host { 'default': model => "el${facts['os']['release']['major']}_x86_64" }
}

