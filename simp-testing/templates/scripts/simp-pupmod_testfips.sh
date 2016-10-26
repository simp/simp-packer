#!/usr/bin/sh
#
#  First check if the fips mode set in the configuration file is the same as the one
#  set in the hiera file.
#  Then check if the system mode is set the same as the hiera file.
export PATH=$PATH:/opt/puppetlabs/bin
source /var/local/simp/scripts/functions.sh
pupenvdir=`puppet config print | grep ^environmentpath | cut -f3 -d" "`
simp_default="${pupenvdir}/simp/hieradata/simp_def.yaml"

simp_conf=SIMP_PACKER_simp_conf_file

fipsmode=`grep ^use_fips $simp_default | cut -f2 -d: | sed -e 's/^ *//g;s/ *$//g'| sort -u`
sc_fipsmode=`grep ^use_fips $simp_conf | cut -f2 -d: | sed -e 's/^ *//g;s/ *$//g'| sort -u`

if [[ $fipsmode -ne $sc_fipsmode ]]; then
  echo "The fips mode in the config file: $sc_fipsmode does not equal the one in simp_def hiera: $fipsmode."
  exit -2
fi

echo "Fips mode is set to $fipsmode"

actualmode=`cat /proc/sys/crypto/fips_enabled`
case $fipsmode in
"false" )
  if [[ $actualmode -ne 0 ]]; then
    echo "Fips_enabled under /proc is set to $actualmode (0=false;1=true) and puppet fips mode is $fipsmode."
    exit -1
  else
    echo "Fipsmode: ${fipsmode} Actualmode is false ... all is well."
  fi
  ;;
"true" )
  if [[ $actualmode -ne 1 ]]; then
    echo "Fips_enabled file under /proc is set to $actualmode and puppet fips mode is $fipsmode."
    echo "This is wrong."
    exit -1
  else
    echo "Fipsmode: ${fipsmode} Actualmode is true ... all is well."
  fi
  ;;
* )
  echo "Error use_fips in simp_def should be true or false."
  echo "It is set to ${fipsmode}"
  exit -1
  ;;
esac

echo "Exiting $0"
exit
