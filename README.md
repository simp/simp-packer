## SIMP Packer manifests

#### Table of Contents

* [Overview](#overview)
* [Setup](#setup)
* [Usage](#usage)
	* [Simple build](#simple-build)
* [Notes](#notes)
* [TODO](#todo)
* [DONE](#done)

### Overview

[Packer](https://packer.io) configuration to build an OVA directly from a fresh [SIMP](https://github.com/NationalSecurityAgency/SIMP) ISO. The OVA that is generated here is intended to be uploaded to Amazon Web Services as an [AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)

### Setup

Requirements:
  - [Packer](https://www.packer.io/downloads.html)
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Usage

Note: The simp-testing folder here is from a previous version of this effort, and has been included for documentation purposes. For now, it doesn't work. 

#### Simple build
1\. Tweak (or generate) the `vars.json` file with appropriate values. Make sure you specify a new public key for the ssh_pub_key field, and that you have the corresponding private key. This is the key that you will use to log in as the packer user after your AMI is running. 

2\. Validate the setup:
```sh
~/bin/packer validate -var-file=vars.json simp.json
```
3\. Run packer:
_(Environment variables and executable path are examples, not suggestions)_
```sh
~/bin/packer build -var-file=vars.json simp.json
```
4\. Alternatively, use some of my favorite [environment variables](https://www.packer.io/docs/other/environmental-variables.html):
```
# PACKER_CACHE_DIR - keeps ginormous tmp files out of /tmp
# PACKER_LOG       - if set with anything, write to a log file
# PACKER_LOG_PATH  - the location of the log file

PACKER_LOG=1 PACKER_LOG_PATH=packerlog.txt PACKER_CACHE_DIR=$PWD/tmp  ~/bin/packer build -var-file=vars.json simp.json
```

5\. Using the default values in `vars.json`, a successful build should drop the new VM under `./OUTPUT`.

#### After build is complete: 
1\. Download and configure the AWS CLI [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html)

2\. Create a storage bucket on AWS or use an existing one.

3\. Upload the OVA created by the packer build to the AWS bucket. 

4\. Use the AMI Import tool to create an AMI from the OVA you just uploaded.

5\. Boot a new EC2 instance using the AMI you've just created. Your security group rules need to allow ssh from your host machine, and need to allow the instance to reach out to yum servers for package updates. In addition, you might need to tweak them to allow SIMP / Puppet to perform certain tasks. The only way to log into the box is with a private key for the packer user, so if you're worried about this you can just open everything. 

6\. When you bring up the new EC2, you will be asked to specify a key pair to use. If you specify a key at this time, it will be the key that you use to log in as the aws_user AFTER simp bootstrap completes. Until then, you will need to log in with the packer user using the key you specified at the start of this process. Alternatively, you can add a key to `/etc/ssh/local_keys/%u` before deleting the packer user. 

6\. Log into the EC2 instance as the packer user with the key you specified before the packer build. 
```
ssh -i <path to private key> packer@<EC2 instance address>
```

7\. Run the `install_simp.sh` script found in `/var/local/packer`. After it completes, choose a new password for the `aws_user` that was created during installation. You should delete the packer user and log in again using the `aws_user` user, and the private key specified when you created the EC2 instance. 

### NOTES:
1\. Both the packer user and the aws_user can access root by default by running the `sudo su root` command. Because of the configuration of /etc/sudoers, other means of switching to the root user are not supported. Feel free to change this any way you like using Puppet after installation is complete. 
2\. The install script sets svckill's mode to `warning`, which prevents it from disabling several services that are necessary to integrate well with AWS. If you enable svckill after installation, you need to add exceptions for these services so that they are not disabled. You probably want to make sure any client nodes that are classified by your SIMP server do the same. 


### TODO
- [ ] modularize `simp.json` sections
- [ ] Add support for other output types, move amazon specific steps (cloud init) into a cloud-specific section
- [ ] Allow user to specify new private key for the packer user after upload to AWS. 
- [ ] Integrate new SIMP scenario functionality from: https://simp-project.atlassian.net/browse/SIMP-2911
