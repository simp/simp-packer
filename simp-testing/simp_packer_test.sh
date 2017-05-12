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

if [[ ! -f $testdir/packer.yaml ]]; then
  echo "$testdir/packer.yaml not found"
  cleanup -1
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

for dir in "files" "manifests" "scripts"; do
   if [[ -d $basedir/$dir ]]; then
     cp -Rp $basedir/$dir $working_dir/$dir
  fi
done

cd $working_dir
# Update the json file with packer.yaml settings and copy to working dir
$basedir/simp_json.rb $basedir/simp.json.template $testdir/packer.yaml
# Update config files with packer.yaml setting and copy to working dir
$basedir/simp_config.rb $working_dir $testdir
#If you use debug you must set header to true or you won't see the debug.
#/bin/packer build --debug -var-file=$testdir/vars.json $working_dir/simp.json &> $logfile
/bin/packer build -var-file=$testdir/vars.json $working_dir/simp.json >& $logfile
if [[ $? -ne 0 ]]; then
  mv $logfile ${logfile}.errors
  cleanup -1
fi

cleanup 0

