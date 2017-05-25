## SIMP Packer manifests

This readme is currently outdated. It is being updated, and will be applicable to the current build by 26 May, 2017

#### Table of Contents

* [Overview](#overview)
* [Setup](#setup)
* [Usage](#usage)
	* [Simple build](#simple-build)
  * [Post build](#after-build-is-complete)
* [Notes](#notes)
* [TODO](#todo)
* [DONE](#done)

### Overview

This repository is a work in progress

[Packer](https://packer.io) configuration to build an OVA directly from a fresh [SIMP](https://github.com/NationalSecurityAgency/SIMP) ISO. The OVA that is generated here is intended to be uploaded to Amazon Web Services as an [AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)

### Setup

Requirements:
  - [Packer](https://www.packer.io/downloads.html)
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Usage

Note: The simp-testing folder here is from a previous version of this effort, and has been included for documentation purposes. For now, it doesn't work.

#### Simple build

* Update vars.json with appropriate values. 
** `fips_enabled` **must** be set to 0 -- AWS does not support FIPS enabled. 
** `iso_url` indicates the path to the SIMP ISO that you intend to build from. This should be a path to a local directory on the build system. 
** `iso_checksum` is a checksum for the ISO, of the type indicated by `iso_checksum_type`.
** `ssh_pub_key` is a public key that is assigned to the packer user during build. If the build should fail, you will be able to log into the machine to diagnose errors with the packer user and this key.
* Start the build process with `packer build -vars-file=vars.josn simp.json`. You can pass the `-on-error=abort` flag to prevent packer from destroying the build machine in the event of a failure. 
* Follow the steps to convert the resuling OVA into an Amazon Machine Image at [this location](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html), or move to the next section of this readme. 
* See the simp documentation at [SIMP's ReadTheDocs](https://simp.readthedocs.io/en/master/getting_started_guide/index.html) for information on using SIMP on AWS and further steps.

#### After build is complete:

* Download and configure the AWS CLI [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html)
* Create an S3 storage bucket on AWS or use an existing one. See [here](http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html) for more information on using S3 storage. 
* Upload the OVA created by the packer build to the AWS bucket. See [here](http://docs.aws.amazon.com/AmazonS3/latest/UG/UploadingObjectsintoAmazonS3.html) for upload documentation. 
* Use the AMI Import tool to create an AMI from the OVA you just uploaded. See [here](https://aws.amazon.com/ec2/vm-import/) for information on the ec2-import service. 
* When you bring up the new EC2, you will be asked to specify a key pair to use. If you specify a key at this time, it will be the key that you use to log in as the ec2-user. If you need to create a user other then the ec2-user before firstboot, you will need to perform additional steps in SIMP to ensure that Puppet does not remove access from the user, and should refer to the Custom Build section of this document.  
* Log into the EC2 instance as the ec2-user with the key you specified before the packer build.
* Switch the the root user by running `sudo su root`, and navigate to the `/usr/share/simp/` directory. 
* Run the `generate_answers.sh` script to populate the `simp_conf.yaml` answers file in the same directory. The answers file will now contain information about your system that can be inferred from AWS. In most cases, these answers will be correct for your system, however if you have a custom configuration inside of AWS you may need to tweak the answers file accordingly. 
* Run `simp config -A simp_conf.yaml` to finish preparing your system for the installation of SIMP. You will be prompted to provide values for all keys not covered by the `simp_conf.yaml` file. More information about simp config can be found in the [documentation](https://simp.readthedocs.io/en/master/getting_started_guide/ISO_Install/SIMP_Server_Installation.html#installing-the-simp-server)

### NOTES:



