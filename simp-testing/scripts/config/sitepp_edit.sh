#!/bin/bash

codedir=`puppet config print environmentpath`
pupenv=`puppet config print environment`
puppetsitepp="${codedir}/${pupenv}/manifests/site.pp"

cp $puppetsitepp ${puppetsitepp}.packer.bak

grep --quiet ^\$hostgroup.*=.*default.$  $puppetsitepp
if [ $? == '0' ]; then
  sed -i -e '/^\$hostgroup.*=.*default.$/d' $puppetsitepp
  cat << EOF >> $puppetsitepp
case \$::hostname {
    /^ws\d+.*/:            { \$hostgroup = 'workstation'        }
    default:               { \$hostgroup = 'default'            }
}
EOF

fi

