#!/bin/sh

SIMP_PACKER_run_simp_config
SIMP_PACKER_run_simp_bootstrap

if [ $SIMP_PACKER_run_simp_config ]
  simp config -a /vagrant/simp_conf.yaml
fi

if [ $SIMP_PACKER_run_simp_bootstrap ]
  simp bootstrap
fi