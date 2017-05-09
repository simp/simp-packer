#!/bin/bash

# This script is responsible for configuring the ec2-user on newly provisioned
# AWS instances. This script is run automatically by cloud-init when the 
# ec2 instance boots. 

# Set the location of cloud-init data
DATA_FILE="/var/lib/cloud/instance/obj.pjl"

# Add the ec2-user
groupadd -g 1800 ec2-user
useradd -d /var/local/ec2-user -g ec2-user -m -s /bin/bash -u 1800 ec2-user
usermod -aG wheel ec2-user
echo 'AllowUsers ec2-user' >> /etc/ssh/sshd_config

# add the ec2-user's ssh key
mkdir /etc/ssh/local_keys
touch /etc/ssh/local_keys/ec2-user
chmod 644 /etc/ssh/local_keys/ec2-user

# get the ssh key from cloud data
# and format it appropriately

SSH_KEY=$(grep -m 1 "S'ssh-rsa" "$DATA_FILE")
SSH_KEY="${SSH_KEY//S\'}"
SSH_KEY="${SSH_KEY//\'}"

# Copy the key over to the ssh keys directory
echo "$SSH_KEY" >> /etc/ssh/local_keys/ec2-user

# Add puppet code to give permissions to the ec2 user
cat <<EOT >> /var/local/ec2-user
pam::access::rule { 'ec2-user':
  permission => '+',
  users      => ['(ec2-user)'],
  origins    => ['ALL'],
  order      => 1000
}

sudo::user_specification { 'ec2-user':
  user_list => ['ec2-user'],
  passwd    => false,
  host_list => [\$facts['ec2_metadata']['hostname']],
  runas     => 'root',
  cmnd      => ['/bin/su root', '/bin/su - root']
}
EOT

puppet apply /var/local/ec2-user

