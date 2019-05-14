#
#  Set up DHCP in rsync
#
# This gets the mac address of the hostonly interface
# (which is assumed to be the second interface because
# the first it the nat interface used by vagrant)
# and builds the DHCP from that info and the first
# part of the puppetservers IP address.
#
# Note:  should probably param server and work station list
#    and mac address from main module
#
# @param $ksip  kickstart server ip
# @param $dnsip IP address of dns server
# @param $domain  Domain name
# @param $fwdaddr the first three octets of the puppetserver IP.
# @param $env   the puppet environment
#
class simpsetup::dhcp (
  String      $ksip      = $simpsetup::ipaddress,
  String      $dnsip     = $simpsetup::ipaddress,
  String      $domain    = $simpsetup::domain,
  String      $fwdaddr   = $simpsetup::fwdaddr,
  String      $env       = $simpsetup::environment,
){

  $rsync_dir = "/var/simp/environments/${env}/rsync/${facts['os']['name']}/Global/dhcpd"

  $iface = $facts['networking']['primary']
  $_macprefix = split($facts['networking']['interfaces'][$iface]['mac'],':')
  $macprefix = $_macprefix[0,5].join(':')


  concat { 'rsync-dhcpd.conf':
    path    => "${rsync_dir}/dhcpd.conf",
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    seltype => 'dhcp_etc_t',
    order   => 'numeric'
  }

  concat::fragment { 'dhcp-header':
    target  => 'rsync-dhcpd.conf',
    order   => 0,
    content => epp('simpsetup/rsync/dhcp/dhcp-header.epp'),
  }

  concat::fragment { 'dhcp-data':
    target  => 'rsync-dhcpd.conf',
    order   => 1,
    content => epp('simpsetup/rsync/dhcp/dhcp-data.epp'),
  }
}

