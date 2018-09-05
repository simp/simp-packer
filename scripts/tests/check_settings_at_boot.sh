#!/bin/sh

set -e

export PATH=$PATH:/opt/puppetlabs/bin

# Checking out if the disks are encrypted ... if it was chosen.
case ${SIMP_PACKER_disk_crypt:-} in
"simp_disk_crypt"|"simp_crypt_disk")
   if ! /bin/lsblk --output FSTYPE,TYPE,NAME | grep "^crypto_LUKS" ; then
      echo "No encrypted disk was found on the system."
      /bin/lsblk
      exit 2
   fi
   ;;
*) ;;
esac

# Check if fips is set correctly at boot
proc_fips=$(cat /proc/sys/crypto/fips_enabled)
case ${SIMP_PACKER_fips:-} in
  "fips=0")
     if [ "$proc_fips" -ne 0 ]; then
       echo "Boot directive $SIMP_PACKER_fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit 3
     fi
     ;;
  "fips=1")
     if [ "$proc_fips" -ne 1 ]; then
       echo "Boot directive $SIMP_PACKER_fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit 4
     fi
     ;;
  *)
     if [ "$proc_fips" -ne 0 ]; then
       echo "Boot directive $SIMP_PACKER_fips, it should default to fips but /proc/sys/crypto/fips_enabled is set to $proc_fips"
       exit 5
     fi
     ;;
esac

echo "Exiting $0"
