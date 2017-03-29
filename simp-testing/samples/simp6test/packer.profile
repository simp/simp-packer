#! /bin/sh
mydate=`date +%y%m%d%H%M%S`
# If you do not want packer to log then comment out the PACKER_LOG variable.
# It should be used for debug only.
# export PACKER_LOG=1
export PACKER_LOG_PATH="/tmp/packerlog.log.${mydate}"
# simp_prompt should be "simp" or  "simp-big"
export SIMP_PACKER_simp_prompt="simp-big"
export SIMP_PACKER_fips="fips=1"
# Should be either "simp_disk_crypt" or "simp_crypt_disk" or ""
export SIMP_PACKER_disk_encrypt=""
# The network interface for the host only will be pulled from the simp_conf.yaml file
# you provide with this.  You need to set here Virtual Box network name for the host
# interface used there.  If your puppet server is on 192.168.100.0 network then make sure
# a host only network with that address is set up on the server and set this variable to
# that name.
export SIMP_PACKER_host_only_network_name="vboxnet0"
# The interface used by packer and Vagrant to connect to the system.
# Network interface is probably eth0 or enp0s3 depending on if the system
# is CentOS 6 or 7.  The name is what ever you made it when creating the
# natNetwork.  NatNetwork is the default name.
export SIMP_PACKER_nat_network_if="enp0s3"
# This is the default name Vitual box uses for the Nat Network.  If you changed your name then
# you must change this variable.
export SIMP_PACKER_nat_network_name="NatNetwork"
# The big sleep is here for padding.  Different systems take a different amount of
# time to complete the set up.  If your packer tries to start typing the answers to questions
# before it is finished installing, the input is lost and the system will fail.  To make it
# so you don't have to edit the code the big_sleep variable was added.  It is an educated guess.
# The only help I can offer is if you are setting this to run automatically, it doesn't matter if it
# waits a long time, add more <wait10> to the variable. The simp.json file waits are tuned to my NUC
# which is only running two or three other virtual servers.
export SIMP_PACKER_big_sleep="<wait10><wait10>"
export SIMP_PACKER_root_password="Puppet"
export SIMP_PACKER_vagrant_password="Vagrant"
