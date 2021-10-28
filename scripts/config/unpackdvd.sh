#!/bin/bash

#FIXME In most cases unpack_dvd needs `-v <version>`, so unclear how useful
# this helper script will be
if [[ -d /var/local/simp/ISO ]]; then
  /usr/local/bin/unpack_dvd /var/local/simp/ISO/*.iso
fi
