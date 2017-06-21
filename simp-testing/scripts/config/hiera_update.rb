#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'socket'


hieradir = '/etc/puppetlabs/code/environments/simp/hieradata'
time = Time.new
# Update the puppetservers hiera file to add new classes for
# kickstart server and install extra modules require by
#  other configuration modules
#
#  NOTE: The site classes added here are created by the simpsetup manifest
hostname = Socket.gethostbyname(Socket.gethostname).first
filename = "#{hieradir}/hosts/#{hostname}.yaml"
backup ="#{filename}" + "." + time.strftime("%Y%m%d%H%M%S")

FileUtils.cp(filename,backup)
puppetyaml = YAML.load_file("#{filename}")

newclasses =  puppetyaml['classes'] + ['simp::server::kickstart','site::tftpboot','site::wsmodules']

puppetyaml['classes'] = newclasses.uniq

File.open("#{filename}",'w') do |h|
     h.write puppetyaml.to_yaml
          h.close
end
FileUtils.chmod 0640, filename
FileUtils.chown 'root', 'puppet', filename


# create hiera file for the workstations host group.
# TODO: if it exist read it in.
wsfilename = "#{hieradir}/hostgroups/workstations.yaml"
if File.exists?(wsfilename)
  backup = "#{wsfilename}" + "." + time.strftime("%Y%m%d%H%M%S")
  FileUtils.cp(wsfilename,backup)
end
wshash = Hash.new
wshash['simp::runlevel'] = 'graphical'
wshash['classes'] = ['site::workstations']

File.open("#{wsfilename}",'w') do |h|
       h.write wshash.to_yaml
       h.close
end
FileUtils.chmod 0640, wsfilename
FileUtils.chown 'root', 'puppet', wsfilename
