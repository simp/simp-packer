#!/bin/sh

  simp bootstrap --remove_ssldir --no-track 
  cat /root/.simp/simp_bootstrap.log*

exit 0
