#!/usr/bin/sh
#
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
 
  return 0
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
