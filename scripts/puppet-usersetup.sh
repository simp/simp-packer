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

simp_version="$(cat /etc/simp/simp.version)"
semver=( ${simp_version//./ } )
major="${semver[0]}"
minor="${semver[1]}"

# Use old hieradata path when SIMP < 6.3.0
if [[ ( "$major" -eq 6  &&  "$minor" -lt 3 ) || "$major" -le 5 ]]; then
  hieradata_dir="$pupenvdir/${env}/hieradata"
  sed -i -e 's@/data$@/hieradata@g' /root/.bashrc-extras
fi

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
classes:
  - 'site::vagrant'

# enable root login over ssh
ssh::server::conf::permitrootlogin: true
# change the default authorized keys file to the users local dir for vagrant
ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
simplib::resolv::option_rotate: false
EOF

chown root:puppet "${hieradata_dir}/default.yaml"
chmod g+rX "${hieradata_dir}/default.yaml"

#puppet apply -e "include site::vagrant" --environment=$env
