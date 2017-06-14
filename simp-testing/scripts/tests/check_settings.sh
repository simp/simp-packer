#!/usr/bin/sh
#
#  Call ruby script to check if system setting, simp_conf.yaml and simp_config_settings.yaml
#  all agree.
export PATH=$PATH:/opt/puppetlabs/bin
packerdir="/var/local/simp"
source $packerdir/scripts/functions.sh
pupenvdir=`puppet config print environmentpath`
simp_default="${pupenvdir}/simp/hieradata/simp_config_settings.yaml"

$packerdir/scripts/tests/check_settings.rb $packerdir/files/simp_conf.yaml $simp_default


