#!/usr/bin/sh
#
# TODO might want to change this to a ruby script since we are reading in yaml files.
#  First check if the fips mode set in the configuration file is the same as the one
#  set in the hiera file.
#  Then check if the system mode is set the same as the hiera file.
packerdir="/var/local/simp"
export PATH=$PATH:/opt/puppetlabs/bin
source $packerdir/scripts/functions.sh
pupenvdir=`puppet config print environmentpath`
simp_default="${pupenvdir}/simp/hieradata/simp_config_settings.yaml"

$packerdir/scripts/tests/check_settings.rb $packerdir/files/simp_conf.yaml $simp_default


