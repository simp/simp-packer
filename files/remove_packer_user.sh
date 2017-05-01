#!/bin/sh

# After your new user is configured and you are sure that you can log in with
# that user, run this script to delete the packer user and it's home directory.

userdel -f -r -Z packer
