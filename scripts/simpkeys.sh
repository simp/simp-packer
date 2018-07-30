#!/bin/bash

ls -laR /var/local/simp

if [ ! -d /etc/ssh/local_keys ]; then
  mkdir /etc/ssh/local_keys
  chmod 755 /etc/ssh/local_keys
fi

cp /var/local/simp/ssh/*pub /etc/ssh/local_keys/simp
chmod 644 /etc/ssh/local_keys/simp

mv /var/local/simp/ssh /var/local/simp/.ssh

