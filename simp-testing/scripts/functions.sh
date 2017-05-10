#!/usr/bin/sh
#
#  Functions used by simp-packer during testing.
# This searchs a configuration file for a value when the 
# name and value in the configuration file are seperated by 
# blank space.
# The parameters are positional
# 1) The string to search for in the file. 
# 2) The full path to the configuration file.
# If the return code is 0, then the global variable myvalue will contain the value of the
#   the configuration item
# If the return code is not zero then an error occurred and the value of the global
#   variable is unreliable.

#  Check if puppet is running on ports 8140 and 8141
#  or what is set in the conf file

function get_value_lower() {
  if [[ $# -ne 2 ]]; then
    echo "usage get_value_lower <search string>  <file to search>"
    return -1
  fi
  file=$2
  if [[ ! -f $file ]]; then
    echo "get_value_lower:  File $file does not exist"
    return -1
  fi
  myvalue=""
  tempstuff=`grep $1 $file | cut -f2 -d' '`
  if [[ $? -eq 0 ]]; then
    myvalue=`echo $tempstuff |tr '[:upper:]' '[:lower:]' |  sed -e 's/^ *//g;s/ *$//g'`
  else
    echo "get_value_lower:  unknown error greping for value"
    return -1
  fi

  return
}


function get_simp_major_version() {
  local __myver=$1
  local simp_major_ver

  if [[ ! -f /etc/simp/simp.version ]]; then
   echo "Could not find /etc/simp/simp.version to determine verion of simp"
   exit -1
  fi

  simp_major_ver=`cat /etc/simp/simp.version|cut -f 1 -d "."`

  case ${simp_major_ver} in
   6|5|4 ) eval $__myver="'$simp_major_version'"
           ;;

   * )     echo "Not a valid version:  $simp_major_ver : should be 4, 5 or 6"
           eval $__myver="'-1'"
           exit -1
           ;;
   esac
}
