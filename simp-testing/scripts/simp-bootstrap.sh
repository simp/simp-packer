#!/bin/sh

# run bootstrap
  echo "**********************"
  echo "Running Simp Bootstrap"
  echo "**********************"

  cat << EOF > /etc/puppetlabs/code/environments/simp/hieradata/default.yaml
---
# enable root login over ssh
ssh::server::conf::permitrootlogin: true
EOF

  chown root:puppet /etc/puppetlabs/code/environments/simp/hieradata/default.yaml
  chmod g+rX /etc/puppetlabs/code/environments/simp/hieradata/default.yaml

  simp bootstrap --remove_ssldir --no-track
# echoing bootstrap log to the log file
  cat /root/.simp/simp_bootstrap.log*

#  Have to execute this or the next provisioning scripts
#  won't be able to ssh and sudo because simp will 
#  have turned off the permissions.
  echo "**********************"
  echo "Configuring simp user"
  echo "**********************"
  /var/local/simp/scripts/puppet-usersetup.sh

  exit 0
