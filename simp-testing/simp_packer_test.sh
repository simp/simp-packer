#! /bin/sh
#
#  usage:  simp_packer_test.sh <fqdn test directory>
#  The test directory should contain 3 files:
#    vars.json:  json file created when the iso is made.  This points to the iso file
#                the ooutput directory and the checksum for the iso.  Make sure these are all set correctly.
#    packer.yaml  which contains setting for the rest of the script and will be used to configure the simp.json
#                 file.  Examples are given in the sample directory.
#    simp_conf.yaml:  use one genrated from simp_cli.  My script will over write things in simp_conf.yaml from settings
#                 in the packer.yaml file.  See the Readme for more information
#
#  TMPDIR:   When running this script make sure you set the linux environment variable TMPDIR to point to a directory that is writeable
#            and has enough space for packer to create the disk for the machine.
#
#  Example usage   TMPDIR=/var/tmp ./simp_packer_test.sh /var/jmg/packer/nofips 
#
#  Where I have copied the sample directory nofips to /var/jmg/packer and edited the packer and vars files to point to my iso.  I also
# have already set up in virtual box the HOST ONLY network refered to in the packer.yaml file.  Or changed it and the IP addresses to 
# point ot one I have already setup.
#
#
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

#cp -R $BASEDIR/ssh $WORKINGDIR
# Update the json file with packer.yaml settings and copy to test directory
$BASEDIR/simp_json.rb $BASEDIR/simp.json.template $TESTDIR/packer.yaml
# Update config files with packer.yaml setting and copy to working dir
$BASEDIR/simp_config.rb $WORKINGDIR $TESTDIR
#If you use debug you must set header to true or you won't see the debug.
#PACKER_LOG=1 PACKER_LOGPATH=/tmp/packer.log.$DATE /bin/packer build -var-file=$TESTDIR/vars.json $WORKINGDIR/simp.json >& $logfile
#TMPDIR="/srv/tmp" SIMP_PACKER_ssh_key="$WORKINGDIR/ssh/simp.key" /bin/packer build -var-file=$TESTDIR/vars.json $WORKINGDIR/simp.json >& $logfile
/bin/packer build -var-file=$TESTDIR/vars.json $WORKINGDIR/simp.json >& $logfile
if [[ $? -ne 0 ]]; then
  mv $logfile ${logfile}.errors
#  cleanup -1
fi

cp $WORKINGDIR/VagrantFile $TESTDIR
cleanup 0

