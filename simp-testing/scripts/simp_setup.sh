#!/bin/bash
#
export PATH=$PATH:/opt/puppetlabs/bin
chown -R root:puppet /var/local/simp/manifests
chmod -R g+rX /var/local/simp/manifests

puppet apply --modulepath /var/local/simp/manifests -e "include simpsetup"

