#!/bin/bash

if [ ! -d ~/.ssh ]; then
  mkdir ~/.ssh
fi

cp /var/local/files/ssh/* ~/.ssh

