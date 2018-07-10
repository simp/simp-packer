#!/bin/bash

if [[ -d /var/local/simp/ISO ]]; then
  /usr/local/bin/unpack_dvd /var/local/simp/ISO/*.iso
fi

exit 0
