# set default hieradata for simp on AWS
echo "  - 'simp::yum::repo::internet_simp_dependencies'" >> /usr/share/simp/environments/simp/hieradata/hosts/puppet.your.domain.yaml
echo " " >> /usr/share/simp/environments/simp/hieradata/hosts/puppet.your.domain.yaml
echo "ssh::server::conf::trusted_nets:" >> /usr/share/simp/environments/simp/hieradata/hosts/puppet.your.domain.yaml
echo "  - 'ALL'" >> /usr/share/simp/environments/simp/hieradata/hosts/puppet.your.domain.yaml

