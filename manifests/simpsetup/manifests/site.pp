# Copy some site manifests to the the site module
#
# simp-packer/simp-testing contains a script that puts these classes into
# hiera.
#
#  @param  $sitedir   The directory where the site manifests are.
#
class simpsetup::site (
  String $sitedir  = '/etc/puppetlabs/code/environments/simp/modules/site/manifests'
){

  $file_perms = {
    'ensure'  => 'file',
    'owner'   => 'root',
    'group'   => 'puppet',
    'mode'    => '0640',
  }
  file { "${sitedir}/tftpboot.pp":
    content => template('simpsetup/site/manifests/tftpboot.pp.erb'),
    *       => $file_perms
  }
  file { "${sitedir}/workstations.pp":
    content => template('simpsetup/site/manifests/workstations.pp.erb'),
    *       => $file_perms
  }
  file { "${sitedir}/wsmodules.pp":
    content => template('simpsetup/site/manifests/wsmodules.pp.erb'),
    *       => $file_perms
  }
}
