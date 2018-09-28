```sh
SIMP_ISO_JSON="${ISO_PATH}/simp/releases/SIMP-6.1.0-0-Powered-by-CentOS-%OS_MAJ_VER%.?-x86_64.json" \
bundle exec rake simp:packer:matrix[os=el6:el7,fips=on]

MATRIX_LABEL=build_6.2.0RC1_ \
SIMP_ISO_JSON=${ISO_PATH}/simp/prereleases/SIMP-6.2.0-RC1.%OS%-CentOS-%OS_MAJ_VER%.?-x86_64.json" \
bundle exec rake simp:packer:matrix[os=el6:el7,fips=on]
```
