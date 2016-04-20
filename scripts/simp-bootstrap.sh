#!/bin/sh

if [[ "$SIMP_PACKER_run_simp_config" = "yes" ]]; then
  simp config -a /vagrant/simp_conf.yaml
fi

if [[ "$SIMP_PACKER_run_simp_bootstrap" = "yes" ]]; then
  simp bootstrap
fi

exit 0
