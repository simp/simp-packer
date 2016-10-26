#! /bin/sh
# If you do not want packer to log then comment out the PACKER_LOG variable.
# It should be used for debug only.
# export PACKER_LOG=1
# export PACKER_LOG_PATH="/tmp/packerlog.log.${mydate}"
# mydate=`date +%y%m%d%H%M%S`
# simp_prompt should be "simp" or  "simp-big"
export SIMP_PACKER_simp_prompt="simp-big"
export SIMP_PACKER_fips="fips=0"
# Should be either "simp_disk_crypt" or "simp_crypt_disk" or ""
export SIMP_PACKER_disk_encrypt=""
# The network interface for the host only will be pulled from the simp_conf.yaml file
# you provide with this.  You need to make sure that Virtual box has a hostonly network set
# up for the IP address.  Set the host_only_network_name to the name of this network.
export SIMP_PACKER_host_only_network_name="vboxnet2"
# The interface used by packer and Vagrant to connect to the system.
# Network interface is probably eth0 or enp0s3 depending on if the system
# is CentOS 6 or 7.  The name is what ever you made it when creating the
#natNetwork.  NatNetwork is the default name.
export SIMP_PACKER_nat_network_if="eth0"
# Virtual box creates a default Nat Network called NatNetwork.  If you have changed the
# name then you will need to reset this variable.  This is the network packer talks to
# server on.
export SIMP_PACKER_nat_network_name="NatNetwork"
# The big sleep is used to pad the amount of time packer waits for the system to install
# before it starts trying to log in and set up the users used by packer.  If you don't wait long
# enough, it starts typying and the input is lost.  It all depends on how fast your system
# is.  The simp.json file was tuned to my NUC which as TB systemes goes is farly fast.  I use
# the short version. If you
# are running this as cron it is better to wait longer then miss the input.
export SIMP_PACKER_big_sleep="<wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10>"
#export SIMP_PACKER_big_sleep="<wait10><wait10>"
export SIMP_PACKER_root_password="Puppet"
export SIMP_PACKER_vagrant_password="Vagrant"
