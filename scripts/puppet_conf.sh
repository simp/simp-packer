#!/bin/bash

sudo cp /var/local/simp/files/puppet.conf /etc/puppet/puppet.conf
sudo chown :puppet /etc/puppet/puppet.conf
sudo chmod 640 /etc/puppet/puppet.conf
