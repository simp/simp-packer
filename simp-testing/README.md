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

[Packer](https://packer.io) configuration to build a [Vagrant](https://www.vagrantup.com/) box directly from a fresh [SIMP](https://github.com/NationalSecurityAgency/SIMP) ISO and run some basic tests that need a full puppet install to verify.   All versions of a SIMP ISO, 4/5/6, can be tested.

### Setup

Requirements:
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
  - [Vagrant](https://www.vagrantup.com/downloads.html)
  - SIMP ISO created from build:auto and its json file.

### Usage
#### Simple build
1\. To define a test, create a test directory and include the following three files:
      vars.json:  The *.json file from the SIMP ISO.  If you have moved the iso
           make sure it points to the location of the SIMP ISO you want to test.
      simp_conf.yaml:  A simp_conf.yaml file with the setup you want to test.
      packer.profile:  A configuration file, a sample is in the sample dir.  Edit
           this file to match your set up.  There is guidance in the sample file.

     You can add additional environment variables like:
	   PACKER_CACHE_DIR - keeps ginormous tmp files out of /tmp
	   PACKER_LOG       - if set with anything, write to a log file
     PACKER_LOG_PATH  - the location of the log file

When setting up your test files make sure to check the following:
   a) The network interfaces.  The default names vboxnet1 were used.  You must have the network configured by VBOXManger before you run the script and you might have used a different name to create your directories.
   b) Make sure the IP addresses in your simp_conf.yaml files are on the network.
   c) The SIMP_PACKER_fips and SIMP_PACKER_network_if  (eth0 or whatever) are defaulted to the settings in your simp_conf.yaml file. 

2\. Run the test: Run the script:
     simp-packer_test.sh <full path to test directory from #1>

It will run and create an output file beginning with the date in the test directory.
All processing is in a temporary working directory created under the test directory.
The script will replace environment variables in the template script and set up and export
environment variables.  It also replaces some variables in the json script and removes
any comments.

3\. Once the environment is set up, packer uses the vars.json file to find the ISO you want to
use.  The vars file also contains the password to be used for the simp login.

packer installs the iso, then packer uses the simp.json file to step it through
configuring simp according to the simp_conf.yaml and running simp bootstrap.
This is done in the build section and the start of the provisioning section.

Once the setup is complete, the tests are run.  These are the final sections in the
provisioning section of the simp.json.template.  Currently
it tests the following:
1) That the build of the puppet server is successful.
2) Puppet server is up and running and listening on the ports configured in simp_conf.yaml
3) It verifies that FIPS is setting match across the simp_conf.yaml, the simp_def.yaml and
   in the operational environment.
4) Checks that selinux matches the simp_conf.yaml selinux::secure setting.
5) If simp_crypt_disk is used in the simp.conf, it verifies that the disk is encrypted.

### Notes
-

### TODO
- test if master is yum that yum is set up and working.

