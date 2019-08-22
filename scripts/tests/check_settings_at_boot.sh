#!/bin/sh

set -e

export PATH=$PATH:/opt/puppetlabs/bin

# Checking out if the disks are encrypted ... if it was chosen.
echo "SIMP_PACKER_disk_encrypt is ${SIMP_PACKER_disk_encrypt:-}"
echo "SIMP_PACKER_fips is ${SIMP_PACKER_fips:-} "

case ${SIMP_PACKER_disk_encrypt:-} in
"true")
   if ! /bin/lsblk --output TYPE,NAME | grep "^crypt" ; then
      echo "Disk encrypt is $SIMP_PACKER_disk_encrypt. but no encrypted disk was found on the system."
      /bin/lsblk --output TYPE,NAME
      exit 2
   fi
   ;;
*)
   if  /bin/lsblk --output TYPE,NAME | grep "^crypt"; then
      echo "Disk encrypt is $SIMP_PACKER_disk_encrypt. Encrypted disk was found on the system but was not expected."
      /bin/lsblk --output TYPE,NAME
      exit 2
   fi
  ;;
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

case ${SIMP_PACKER_firmware:-} in
  "bios")
    if [ -d /sys/firmware/efi ]; then
      echo "System appears to have booted in EFI mode, not LEGACY BIOS.  Packer may be configured wrong."
      exit 6
    fi
    ;;
  "efi")
    if [ ! -d /sys/firmware/efi ]; then
      echo "System appears to have booted in EFI mode, not LEGACY BIOS.  Packer may be configured wrong."
      exit 6
    fi
    ;;
  *)
    echo "Unknown value ${SIMP_PACKER_firmware:-} for firmware.  Cannot verify the setting"
    ;;
esac

echo "Exiting $0"
