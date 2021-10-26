#!/bin/sh

#  Because this script is used before the reboot the path is not
#  set for simp user so I add this to the end
#  incase it is Puppet 4.0
export PATH="${PATH}:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"
packerdir="/var/local/simp"
pupenvdir=$(puppet config print environmentpath 2> /dev/null)
env=$(puppet config print environment 2> /dev/null)
puppetmodpath="${pupenvdir}/${env}/modules"
hieradata_dir="${pupenvdir}/${env}/data"

echo "The puppet environment directory is: $pupenvdir"
echo "The hiera data directory is: $hieradata_dir"

# Install site module
cp -R "${packerdir}/puppet/modules/site" "${puppetmodpath}/"
chmod -R g+rX "${puppetmodpath}/site"
chown -R root:puppet "${puppetmodpath}/site"

# Include the vagrant manifest in  default along with
# other hiera settings to configure the vagrant user
cat << EOF > "${hieradata_dir}/default.yaml"
---
simp::classes:
  - 'site::vagrant'

# enable root login over ssh
ssh::server::conf::permitrootlogin: true
# change the default authorized keys file to the users local dir for vagrant
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
simplib::resolv::option_rotate: false
EOF

chown root:puppet "${hieradata_dir}/default.yaml"
chmod g+rX "${hieradata_dir}/default.yaml"

# Need to add to Puppetfile in the environment as a local module
# or it will be removed when upgrading and r10K is called.
echo "mod 'site', :local => true" >> "${pupenvdir}/${env}/Puppetfile"
