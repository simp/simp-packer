#!/bin/bash
#

chown -R root:puppet /var/local/simp/manifests
chmod -R g+rX /var/local/simp/manifests

puppet apply --modulepath /var/local/simp/manifests -e "include simpsetup"

