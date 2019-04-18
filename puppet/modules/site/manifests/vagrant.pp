# Sets up vagrant user to be able to ssh in and
# have root priveledges.
# Adds Virtual Box services so svckill will not
# kill them.
#
# @author https://github.com/simp/simp-packer/graphs/contributors
class site::vagrant {
  pam::access::rule { 'vagrant_simp':
    permission => '+',
    users      => ['vagrant','simp'],
    origins    => ['ALL'],
  }

  # The vagrant user needs Password-less Sudo
  #
  #   https://www.vagrantup.com/docs/boxes/base.html#password-less-sudo
  #
  sudo::user_specification { 'vagrant_passwordless_sudo':
    user_list => ['vagrant'],
    host_list => ['ALL'],
    cmnd      => ['ALL'],
    passwd    => false,
  }

  sudo::user_specification { 'simp_sudo':
    user_list => ['simp'],
    host_list => ['ALL'],
    cmnd      => ['ALL'],
    passwd    => false,
  }

  sudo::default_entry { 'simp_default_notty':
    content  => ['!env_reset, !requiretty'],
    target   => 'simp',
    def_type => 'user'
  }

  sudo::default_entry { 'vagrant_default_notty':
    content  => ['!env_reset, !requiretty'],
    target   => 'vagrant',
    def_type => 'user'
  }

  # Make vboxadd* services known to svckill
  service { 'vboxadd': }
  service { 'vboxadd-service': }
}
