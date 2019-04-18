#! /bin/sh
#
#  This is used to create a new environment and will be replaced 
#  when simp env is working
#
skeldir=/usr/share/simp/environments/simp
destdir_base=/etc/puppetlabs/code/environments
destdir="${destdir_base}/simp"
env2dir=/var/simp/environments/simp

if [[ ! -d $destdir ]]; then
  mkdir $destdir
fi

cd $skeldir
#create prime env
tar c data environment.conf manifests hiera.yaml | (cd $destdir; tar x)
chown -R root:puppet ${destdir}
chmod -R g+rX ${destdir}

if [[ ! -d $env2dir ]]; then
  mkdir -p $env2dir
fi
cd $skeldir
tar c simp_autofiles FakeCA site_files | (cd $env2dir; tar x)
chown -R root:puppet $env2dir
chmod -R g+rX $env2dir

exit 0
