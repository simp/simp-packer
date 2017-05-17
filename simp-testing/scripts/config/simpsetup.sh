#!/bin/bash
# TODO, just make this a module and install it.
packerdir="/var/local/simp"
codedir=`puppet config print environmentpath`
pupenv=`puppet config print environment`
puppetmodpath="${codedir}/${pupenv}/modules"

cp -R $packerdir/manifests/simpsetup $puppetmodpath
chmod -R g+rx $puppetmodpath/simpsetup
chown -R root:puppet $puppetmodpath/simpsetup

puppet apply -e "include simpsetup"
