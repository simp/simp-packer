#!/usr/bin/sh
export PATH=$PATH:/opt/puppetlabs/bin

# Checking out if the disks are encrypted ... if it was chosen.
/bin/lsblk --output FSTYPE,TYPE,NAME | grep "^crypto_LUKS"
return_crypt=$?

case $SIMP_PACKER_disk_crypt in
"simp_disk_crypt"|"simp_crypt_disk")
   if [ "$return_crypt" -ne 0 ]; then
      echo "No encrypted disk was found on the system."
      /bin/lsblk
      exit -2
   fi
   ;;
*) ;;
esac

# Check if fips is set correctly at boot

proc_fips=$(cat /proc/sys/crypto/fips_enabled)
case $SIMP_PACKER_fips in
  "fips=0")
     if [ "$proc_fips" -ne 0 ]; then
       echo "Boot directive $SIMP_PACKER_fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit -2
     fi
     ;;
  "fips=1")
     if [ "$proc_fips" -ne 1 ]; then
       echo "Boot directive $SIMP_PACKER_fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit -2
     fi
     ;;
  *)
     if [ "$proc_fips" -ne 0 ]; then
       echo "Boot directive $SIMP_PACKER_fips, it should default to fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit -2
     fi
     ;;
esac

echo "Exiting $0"
exit 0
