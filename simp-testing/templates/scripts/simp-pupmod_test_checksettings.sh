#!/usr/bin/sh
export PATH=$PATH:/opt/puppetlabs/bin
source /var/local/simp/scripts/functions.sh

## Get the selinux setting

get_value_lower "^\"selinux::ensure\":" SIMP_PACKER_simp_conf_file
#get_value_lower "^\"selinux::ensure\":" /srv/jmg/packer/mypacker/simp_conf.yaml

se_value=`/sbin/getenforce | tr '[:upper:]' '[:lower:]'`

if [[ $myvalue -ne $se_value ]]; then
   echo "SELINUX set to $myvalue in config file but system set to $se_value"
   exit -2
fi

echo "Configuration: $myvalue and System $se_value agree"

# Checking out if the disks are encrypted ... if it was chosen.
/bin/lsblk --output FSTYPE,TYPE,NAME | grep "^crypto_LUKS"
return_crypt=$?

case $SIMP_PACKER_disk_crypt in
"simp_disk_crypt"|"simp_crypt_disk")
   if [[ $return_crypt -ne 0 ]]; then
      echo "No encrypted disk was found on the system."
      echo "`/bin/lsblk`"
      exit -2
   fi
   ;;
*) ;;
esac
echo "Exiting $0"
exit 0
