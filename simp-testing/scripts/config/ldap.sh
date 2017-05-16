#!/bin/bash
#
#  This will populate the ldap directory with test users for the 
#  ldifs in the ldif directory
#
#  These files were edited to match the domain by simp_config.rb.
packer_dir=$SIMP_PACKER_directory

cd $packer_dir/files/ldifs

./ldap.sh ./add.ldifs
./lmod.sh ./mod.ldifs
