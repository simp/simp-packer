#!/usr/bin/sh
export PATH=$PATH:/opt/puppetlabs/bin
source /var/local/simp/scripts/functions.sh

## Get the selinux setting
#
get_value_lower "^\"selinux::ensure\":" $SIMP_PACKER_simp_conf_file

se_value=`/sbin/getenforce | tr '[:upper:]' '[:lower:]'`

if [[ $myvalue -ne $se_value ]]; then
   echo "SELINUX set to $myvalue in config file but system set to $se_value"
   exit -2
fi

echo "SELINUX Configuration: $myvalue and System: $se_value values agree"

echo "Exiting $0"
exit 0
