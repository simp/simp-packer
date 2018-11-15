#!/bin/sh

ORIGINAL_UMASK="$(umask)"

# TODO: this hack is not a permanent solution.
# shellcheck disable=SC2039
if [[ "$(cat /etc/simp/simp.version)" =~ ^6\.1\.0- ]]; then
 echo "====================================================="
 echo "====================================================="
 echo "================   SIMP 6.1.0  ======================"
 echo "====================================================="
 echo "====================================================="
 echo "======= SIMP-4482 hack: setting umask to 0022 ======="
 echo "====================================================="
 echo "====================================================="
 echo "====================================================="
 umask 0022
fi

# run bootstrap
echo "**********************"
echo "Running Simp Bootstrap"
echo "**********************"
echo  'umask:'
umask
simp bootstrap --remove_ssldir --no-track
# echoing bootstrap log to the log file
echo "**********************"
echo "Bootstrap Log"
echo "**********************"

cat /root/.simp/simp_bootstrap.log*
echo "****** End of Bootstrap Log ****************"

#  Have to execute this or the next provisioning scripts
#  won't be able to ssh and sudo because simp will
#  have turned off the permissions.
echo "**********************"
echo "Configuring simp user"
echo "**********************"
/var/local/simp/scripts/puppet-usersetup.sh

# TODO: this hack is not a permanent solution.
# shellcheck disable=SC2039
if [[ "$(cat /etc/simp/simp.version)" =~ ^6\.1\.0- ]]; then
 chmod go=u-w /etc/puppetlabs/puppet/puppetdb.conf

 echo "====================================================="
 echo "====================================================="
 echo "================   SIMP 6.1.0  ======================"
 echo "====================================================="
 echo "====================================================="
 echo "==== SIMP-4482 hack: reverting to original umask ===="
 echo "====================================================="
 echo "====================================================="
 echo "====================================================="
 umask "$ORIGINAL_UMASK"
fi
