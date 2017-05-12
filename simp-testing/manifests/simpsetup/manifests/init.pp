class simpsetup
   String              $domain = $fact["domain"],
   String              $dnsserver = $facts['fqdn'],
   String              $ipaddress = $facts['ipaddress']
   String              $relver = $facts['os']['release']['major'],
   Array[String]       $servers = ['21','22','23','24','25','26','27','28','29'],
   Array[String]       $clients = ['31','32','33','34','35','36','37','38','39'],
#   Simplib::Netlist    $trusted_nets = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.01'] })

{


  $fwdaddr = ($ipaddress.split("."))[0,3].join(".")
  $allowed_nets = "${fwdaddr}.0/24"

  include simpsetup::dns
  include simpsetup::dhcp
  include simpsetup::ks

}
