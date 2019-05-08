#!/usr/bin/env ruby
#
require 'fileutils'
environment=ENV['SIMP_PACKER_environment'] || 'production'
sitepp_file = "/etc/puppetlabs/code/environments/#{environment}/manifests/site.pp"
backup_sitepp_file = "/etc/puppetlabs/code/environments/#{environment}/manifests/site.pp.packer.backup"

if File.file?(backup_sitepp_file)
  puts "site.pp backup was found: #{backup_sitepp_file}.  This script will not run again."
else
  FileUtils.cp sitepp_file, backup_sitepp_file
  h = File.open(sitepp_file, 'w')
  f = File.open(backup_sitepp_file, 'r')
  # remove all the comments I put in the json file
  # so I could remember why I did stuff
  f.each do |line|
    if   line =~ %r{^\$hostgroup.*=.*default.$}
      h.puts "case \$facts['fqdn'] {"
      h.puts " /^ws\\d+.*/:           { \$hostgroup = 'workstations'       }"
      h.puts " default:               { \$hostgroup = 'default'            }"
      h.puts '}'
    else
      h.puts line
    end
  end
  f.close
  h.close
end
