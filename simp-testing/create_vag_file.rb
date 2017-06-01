#!/usr/bin/env ruby
class VagrantFile
  def initialize(name,ip,mac)
    @name = name;
    @ipaddress = ip;
    @mac = mac;
    @template = File.read('./templates/Vagrantfile.erb')
  end

  def render
    ERB.new(@template).result( binding )
  end
end

require 'erb'



erb = VagrantFile.new('SIMP_CENTOS7_NOFIPS', '192.168.101.7','aabbbbaa0007')
print erb.render

