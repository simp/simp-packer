#!/bin/bash

set -e

# TODO: just make this a module and install it.
export PATH=$PATH:/opt/puppetlabs/puppet/bin
packerdir="/var/local/simp"
codedir=$(puppet config print environmentpath)
pupenv=$(puppet config print environment)
puppetmodpath="${codedir}/${pupenv}/modules"

cp -R "${packerdir}/puppet/modules/simpsetup" "${puppetmodpath}/"
chmod -R g+rx "${puppetmodpath}/simpsetup"
chown -R root:puppet "${puppetmodpath}/simpsetup"

puppet apply -e 'include simpsetup'
