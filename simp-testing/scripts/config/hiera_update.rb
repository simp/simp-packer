#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'socket'

hieradir = '/etc/puppetlabs/code/environments/simp/hieradata'
time = Time.new
hostname = Socket.gethostbyname(Socket.gethostname).first
filename = "#{hieradir}/hosts/#{hostname}.yaml"
backup ="#{filename}" + "." + time.strftime("%Y%m%d%H%M%S")

FileUtils.cp(filename,backup)
puppetyaml = YAML.load_file("#{filename}")

newclasses =  puppetyaml['classes'] + ['simp::server::kickstart','site::tftpboot']

puppetyaml['classes'] = newclasses.uniq

File.open("#{filename}",'w') do |h|
     h.write puppetyaml.to_yaml
          h.close
end
