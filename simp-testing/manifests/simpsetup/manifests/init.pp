# This is intended for use with the simp-packer module.
#
# simpsetup si used to configure SIMP for testing/CI
# It will take the hostname of the puppetserver, ip and
# mac and generate DNS/DHCP, the Kickstart server, add
# users to LDAP, set up autosigning, generate server
# certs.
#
# It currently bases everything on the IP, mac and FQDN
# of the puppet server.   It assumes a class C network and
# changes the last part of the IP and mac to generate ten
# servers named server##.<domain name> and ten workstations
# ws##.<domain name>
#
# @param $domain
# @param $dnsserver The name of the dnsserver. (should be
#                   puppet server.  It won't work for a remote
#                   server.)
# @param $ipaddress The ipaddress of the puppet server
# @param $relver    The OS release version. (Only works for CentOS)
# @param $servers   The last octet of the IP for a list of servers to
#                   to set up data for.
# @param $clients   The last octet of the IP for a list of workstations
#                   to set up data.
# NOTE: The site.pp file is edited in another script in packer.
#
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
