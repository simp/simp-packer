# This script does the following:
# 1: Tet the HOSTNAME (and other data) from cloud-init
#
# 2: Update the simp-config answers file with the new HOSTNAME, etc


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
sed -i "s/PLACEHOLDER_HOSTNAME/$HOSTNAME/g" simp_conf.yaml

# ... with the new DNS SEARCH
sed -i "s/PLACEHOLDER_DNS/$DNS_SEARCH/g" simp_conf.yaml

# ... with the new LDAP DN
sed -i "s/PLACEHOLDER_LDAP/$LDAP_DN_DC/g" simp_conf.yaml

# ... with the new ip_address
sed -i "s/PLACEHOLDER_IP/$IP_ADDRESS/g" simp_conf.yaml


echo "Done updating obvious answers in answers file."
echo "Run simp config -A simp_conf.yaml to complete configuration."

