class simpsetup(
  String           $domain = $facts['domain'],
  String           $dnsserver = $facts['networking']['fqdn'],
  String           $ipaddress = $facts['networking']['ip'],
  String           $relver = $facts['os']['release']['major'],
  Array[String]    $servers = ['21','22','23','24','25','26','27','28','29'],
  Array[String]    $clients = ['31','32','33','34','35','36','37','38','39']
){

  $_ip = split($ipaddress,'\.')
  $fwdaddr = join($_ip[0,3],'.')
  $lastip  = $_ip[3]
  $revaddr = join(reverse($_ip[0,3]),'.')
  $allowed_nets = "${fwdaddr}.0/24"

  include simpsetup::dns
  include simpsetup::dhcp
  include simpsetup::ks
  include simpsetup::togen
  include simpsetup::ldap
  include simpsetup::autosign
  include simpsetup::site
}
