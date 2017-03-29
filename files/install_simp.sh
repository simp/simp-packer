# this is a shell script that does the following:
#
# 1: get the HOSTNAME (and other data) from cloudinit
# 
# 2: update the simp-config answers file with the new HOSTNAME, etc
# 
# 3: run simp-config with the new answers file
#
# 4: update node classification appropriately
#   4.1: add cloudinit and amazon services to the list of services for svckill to not kill
#   4.2: allow ssh from machines outside the current trusted_nets
#   4.3: create user-specified new user, get pub key from cloud init, add it to sudoers and pam   
#
# 5: run simp bootstrap and wait for it to complete
#
#
#
# 1: get the hostname from the cloud data:

DATA_FILE="/var/lib/cloud/instance/obj.pkl"

# Trim the extra S'...' off the hostname 

HOSTNAME=$(grep -m 1 "S'ip-" "$DATA_FILE")
HOSTNAME="${HOSTNAME//S\'}"
HOSTNAME="${HOSTNAME//\'}"
echo "New HOSTNAME: $HOSTNAME"

# get the dns_search string from the hostname:
REMOVE_STRING=$(echo "$HOSTNAME" | grep -o -P "ip-.*?\.")
DNS_SEARCH="${HOSTNAME//${REMOVE_STRING}}"
echo "New DNS_SEARCH string: $DNS_SEARCH"

# get ldap dn from dns search string
LDAP_DN_DC="${DNS_SEARCH//.compute.internal}"
echo "New LDAP domain info: $LDAP_DN_DC"

IP_ADDRESS="${HOSTNAME//ip-}"
IP_ADDRESS="${IP_ADDRESS//.$DNS_SEARCH}"
IP_ADDRESS="${IP_ADDRESS//-/.}"
echo "New IP_ADDRESS: $IP_ADDRESS"

# 2: Update the simp-config answers file with new hostname
sed -i "s/ip-172-31-11-170.us-west-2.compute.internal/$HOSTNAME/g" simp_conf.yaml

# ... with the new DNS SEARCH
sed -i "s/us-west-2.compute.internal/$DNS_SEARCH/g" simp_conf.yaml

# ... with the new LDAP DN
sed -i "s/dc=us-west-2/dc=$LDAP_DN_DC/g" simp_conf.yaml

# ... with the new ip_address
sed -i "s/172.31.11.170/$IP_ADDRESS/g" simp_conf.yaml


echo "Done replacing hostname etc in simp_conf, running simp config"

# run simp config
simp config -A simp_conf.yaml

echo "simp config complete"

# 4: update host hiera configuration with new stuff
# Get path to file:
FQDN_YAML_FILE="/etc/puppetlabs/code/environments/simp/hieradata/hosts/$HOSTNAME.yaml"

echo "$FQDN_YAML_FILE"

echo "adding hieradata"
echo "svckill::mode: 'warning'" >> $FQDN_YAML_FILE
echo "ssh::server::conf::trusted_nets:" >> $FQDN_YAML_FILE
echo "  - 'ALL'" >> $FQDN_YAML_FILE

# default password hash for the aws user, ideally you'll never log into the user with the password sooooo
pass_hash='$6$5SnplwrFxmHy4j/v$WgcZV1.W6/wQq1SJh/gnV7E5Tr1iIuJgdCFmhdlzHnCdWR927Q/Q4eKZXtFAVOY7eNRb3e30ezM5xbmP8G7t50'

# add the aws_user
groupadd -g 1800 aws_user
useradd -d /var/local/aws_user -g aws_user -m -p $pass_hash -s /bin/bash -u 1800 -K PASS_MAX_DAYS=90 -K PASS_MIN_DAYS=1 -K PASS_WARN_AGE=7 aws_user
usermod -aG wheel aws_user
chage -d 0 aws_user
echo 'AllowUsers aws_user' >> /etc/ssh/sshd_config

# add the aws_user's ssh key
mkdir /etc/ssh/local_keys
touch /etc/ssh/local_keys/aws_user
chmod 644 /etc/ssh/local_keys/aws_user

# get the ssh key from the cloud data
# Trim the extra S'...' off the hostname 

SSH_KEY=$(grep -m 1 "S'ssh-rsa" "$DATA_FILE")
echo "$SSH_KEY"
SSH_KEY="${SSH_KEY//S\'}"
SSH_KEY="${SSH_KEY//\'}"
echo "$SSH_KEY"

# copy public key for user over to new place
echo "$SSH_KEY" >> /etc/ssh/local_keys/aws_user

# 4: update site.pp with new stuff:
# get path to file:
SITE_MANIFEST="/etc/puppetlabs/code/environments/simp/manifests/site.pp"

# add pam access rule for a user:
echo "adding access rules in site.pp"
cat <<EOT >> $SITE_MANIFEST
pam::access::rule { 'aws_user':
  permission => '+',
  users      => ['(aws_user)'],
  origins    => ['ALL'],
  order      => 1000
}

sudo::user_specification { 'aws_user':
  user_list => ['aws_user'],
  passwd    => false,
  host_list => [\$facts['ec2_metadata']['hostname']],
  runas     => 'root',
  cmnd      => ['/bin/su root', '/bin/su - root']
}
EOT


# run simp bootstrap 
simp bootstrap

