#!/usr/bin/env ruby
class VagrantFile
  def initialize(hash)
    hash.each do |key, value|
       singleton_class.send(:define_method, key) { value }
    end
  end

  def getbinding
    binding
  end
end

require 'erb'


template = File.read('./templates/Vagrantfile.erb')

erb = VagrantFile.new(name: 'SIMP_CENTOS7_NOFIPS', ipaddress: '192.168.101.7',mac: 'aabbbbaa0007')
print ERB.new(template).result(erb.getbinding)

