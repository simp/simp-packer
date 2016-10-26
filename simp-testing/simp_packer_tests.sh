#! /bin/sh
source ./scripts/functions.sh

function cleanup () {
  exitcode=${1:0}

  cd $testdir

  case $SIMP_PACKER_save_working_dir in
  "yes" )
      ;;
   *)
      rm -rf $working_dir
      ;;
   esac

  exit $exitcode

    cd $testdir
    rm -rf $working_dir
}

#This routine will pull variables from the simp_conf file and and set them up as
#environment variables in packer.profile so you only have to set the variables once.
#It also sets some profile variables that used by the scripts or in packer
# that the user shouldn't change.
#
function parse_confile () {
  conffile=$1
  grep -q "SIMP_PACKER_fips" $working_dir/packer.profile
  returncode=$?
  if [[ $returncode -ne 0 ]]; then
  if [[ `grep "SIMP_PACKER_fips" $working_dir/packer.profile` -ne 0 ]]; then
    myvalue=""
    get_value_lower "^use_fips:" $conffile
    case $myvalue in
    "false" )
       SIMP_PACKER_fips='fips=0'
       ;;
    *)
      SIMP_PACKER_fips='fips=1'
      ;;
  esac
  echo >> $working_dir/packer.profile "export SIMP_PACKER_fips=$SIMP_PACKER_fips"
 fi

  myvalue=""
  get_value_lower "^\"network::interface\":" $conffile
  echo "export SIMP_PACKER_host_only_network_if=$myvalue" >> $working_dir/packer.profile
  echo "export SIMP_PACKER_simp_conf_file='/var/local/simp/files/simp_conf.yaml'" >> $working_dir/packer.profile
}

# Basedir should be the simp-packer directory where this executable is.
# Test dir should be the directory where the test files exist.  It
# should be writable. The working directory will be created under here.
# The working directory will be removed when finished so don't put output there.

basedir=`pwd`
testdir=$1

if [[ ! -d $testdir ]]; then
  echo "$testdir not found"
  exit -1
fi

working_dir="${testdir}/`basename $0`.working.`date +%y%m%d%H%M%S`"
logfile=${testdir}/`date +%y%m%d%H%M%S`.`basename $0`.log
if [[ -d $working_dir ]]; then
   rm -f ./$working_dir
fi

mkdir -p $working_dir/files
cd $working_dir

if [[ ! -f $testdir/packer.profile ]]; then
  echo "$testdir/packer.profile not found"
  cleanup -1
else
  cp $testdir/packer.profile $working_dir/packer.profile
fi

if [[ ! -f $testdir/simp_conf.yaml ]]; then
  echo "$testdir/simp_conf.yaml  not found"
  cleanup -1
else
  cp $testdir/simp_conf.yaml $working_dir/files/simp_conf.yaml
fi

if [[ ! -f $testdir/vars.json ]]; then
  echo "$testdir/vars.json Not found"
  cleanup -1
fi
parse_confile $working_dir/files/simp_conf.yaml
source $working_dir/packer.profile

# Debug should be removed
printenv | grep SIMP
sleep 10

cat << EOF > $working_dir/sed.script
  s/SIMP_PACKER_nat_network_if/$SIMP_PACKER_nat_network_if/g
  s/SIMP_PACKER_nat_network_name/$SIMP_PACKER_nat_network_name/g
  s/SIMP_PACKER_host_only_network_name/$SIMP_PACKER_host_only_network_name/g
  s/SIMP_PACKER_host_only_network_if/$SIMP_PACKER_host_only_network_if/g
  s@SIMP_PACKER_simp_conf_file@$SIMP_PACKER_simp_conf_file@g
EOF

for dir in "files" "manifests" "scripts"; do
   if [[ -d $basedir/$dir ]]; then
     cp -Rp $basedir/$dir $working_dir/$dir
     for file in `ls ${basedir}/templates/${dir}` ; do
       sed -f $working_dir/sed.script  < ${basedir}/templates/${dir}/$file > $working_dir/$dir/$file
     done
  fi
done

sed -e '/^##/ d' < $basedir/simp.json.template > $working_dir/simp.json

cd $working_dir
#packer build --debug -var-file=$testdir/vars.json $working_dir/simp.json
packer build -var-file=$testdir/vars.json $working_dir/simp.json >& $logfile
if [[ $? -ne 0 ]]; then
  mv $logfile ${logfile}.errors
  cleanup -1
fi

cleanup 0

