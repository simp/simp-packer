#!/bin/sh
#
# chkconfig: 2345 20 80
# description: Remove the packer user during export

userdel --force --remove packer
chkconfig --del /etc/init.d/remove_packer_user
rm -f /etc/init.d/remove_packer_user
rm -rf /var/local/packer
