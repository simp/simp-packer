#!/bin/sh

ORIGINAL_UMASK="$(umask)"

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
