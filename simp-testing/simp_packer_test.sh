#! /bin/sh
source ./scripts/functions.sh

function cleanup () {
  exitcode=${1:0}

  cd $TESTDIR

  case $SIMP_PACKER_save_WORKINGDIR in
  "yes" )
      ;;
   *)
      rm -rf $WORKINGDIR
      ;;
   esac

  exit $exitcode

}

# Basedir should be the simp-packer directory where this executable is.
# Test dir should be the directory where the test files exist.  It
# should be writable. The working directory will be created under here.
# The working directory will be removed when finished so don't put output there.
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
TESTDIR=$1
DATE=`date +%y%m%d%H%M%S`

if [[ ! -d $TESTDIR ]]; then
  echo "$TESTDIR not found"
  exit -1
fi



WORKINGDIR="${TESTDIR}/working.${DATE}"
logfile=${TESTDIR}/${DATE}.`basename $0`.log
if [[ -d $WORKINGDIR ]]; then
   rm -rf ./$WORKINGDIR
fi
mkdir $WORKINGDIR

if [[ ! -f $TESTDIR/packer.yaml ]]; then
  echo "${TESTDIR}/packer.yaml not found"
  cleanup -1
fi

if [[ ! -f $TESTDIR/simp_conf.yaml ]]; then
  echo "${TESTDIR}/simp_conf.yaml  not found"
  cleanup -1
fi

if [[ ! -f $TESTDIR/vars.json ]]; then
  echo "${TESTDIR}/vars.json Not found"
  cleanup -1
fi

for dir in "files" "manifests" "scripts"; do
   if [[ -d $BASEDIR/$dir ]]; then
     cp -Rp $BASEDIR/$dir $WORKINGDIR/
  fi
done

cd $WORKINGDIR

cp -R $BASEDIR/ssh $WORKINGDIR
# Update the json file with packer.yaml settings and copy to test directory
$BASEDIR/simp_json.rb $BASEDIR/simp.json.template $TESTDIR/packer.yaml
# Update config files with packer.yaml setting and copy to working dir
$BASEDIR/simp_config.rb $WORKINGDIR $TESTDIR
#If you use debug you must set header to true or you won't see the debug.
#PACKER_LOG=1 PACKER_LOGPATH=/tmp/packer.log.$DATE /bin/packer build -var-file=$TESTDIR/vars.json $WORKINGDIR/simp.json >& $logfile
SIMP_PACKER_ssh_key="$WORKINGDIR/ssh/simpkey" /bin/packer build -var-file=$TESTDIR/vars.json $WORKINGDIR/simp.json >& $logfile
if [[ $? -ne 0 ]]; then
  mv $logfile ${logfile}.errors
  cleanup -1
fi

cleanup 0

