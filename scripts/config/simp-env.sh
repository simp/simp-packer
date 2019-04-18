#! /bin/sh
function error_msg () {
  printf $1
  if [[ $# -ne 2 ]]; then
    exit 2
  else
    exit 42
  fi
}

function newenv2 () {
usage <<EOU
Usage: newenv2ENVNAME TYPE [EXISTINGENV]
  where TYPE is
    -n copying a new environment from /usr/share/simp
    -l links the new environment to EXISTINGENV
    -c copies the new environment from EXISTINGENV
EOU

  if [[ $# -lt 2 ]]; then
    error_msg "$usage" "5"
  fi

  safe_name=$(echo $1 | tr '[:space:]' '_')

  type=$(echo $2 | tr '[:upper:]' '[:lower:]')

  newenvdir="${destdir}/${safe_name}"

  if [[ -d $newenvdir ]]; then
    errormsg "Environment ${safe_name} exists.  Cannot create" "5"
  fi

  case "${type}"  in
  -l|-c)
     if [[ $# -ne 2 ]]; then
       error_msg "$usage" "5"
     fi
     existing_env=${destdir}/${3}
     if [[ ! -d $existing_env ]]; then
       error_msg "Environment ${3} does not exist.  Can not copy or link to it" "5"
     fi
     existing_env2=${env2base}/${3}
     if [[ ! -d $existing_env2 ]]; then
       error_msg "Secondary environment ${3} does not exist.  Can not copy or link to it" "5"
     fi
     ;;
   -n)
     existing_env2=${skeldir}
     ;;
   *)
     error_msg "$usage" "5"
     ;;
  esac


  case $type in
    -c)
      mkdir ${newenvdir}
      cp -R "${existing_env2}/*" ${newenvdir}
      chown -R root:puppet ${newenvdir}
      chmod -R g+rX ${newenvdir}
      ;;
    -n) 
      mkdir ${newenvdir}
      cd ${skeldir}
      tar c FakeCA  simp_autofiles site_files | (cd ${newenvdir}; tar x)
      chown -R root:puppet ${newenvdir}
      chmod -R g+rX ${newenvdir}
      ;;
    -l}
      cd ${env2base} 
      ln -s ${3} ${safe_name}
      ;;
  esac

}
      


skeldir=/usr/share/simp/environments/simp
destdir="$(puppet config print environmentpath 2> /dev/null)"
env2base="/var/simp/environments/"

cp -R $skeldir $destdir
chown -R root:puppet ${destdir}/simp
chmod -R g+rX ${destdir}/simp

mkdir -p $env2dir
cp -R ${skeldir}/site_files $env2dir
cp -R ${skeldir}/simp_autofiles $env2dir
cp -R ${skeldir}/FakeCA $env2dir
chown -R root:puppet $env2dir
chmod -R g+rX $env2dir

yum install simp-vendored-r10k
