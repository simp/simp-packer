#!/bin/bash
#
packerdir="/var/local/simp"

cp -R $packerdir/simpsetup `puppet config print environmentpath`/simp/modules

cd `puppet config print environmentpath`/simp/modules

chown -R root:puppet simpsetup
chmod -R g+rX simpsetup

puppet apply -e "include simpsetup"

