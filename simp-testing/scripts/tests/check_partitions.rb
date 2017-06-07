#! /usr/bin/env ruby

partition_list = [ '/var','/var/log','/var/log/audit', '/' ]
x = %x(df -h)
y = x.split("\n") 

mount_hash = Hash.new
y.each{|m|
  mount = m.split(' ')
  mount_hash["#{mount[5]}"] = mount[0]
}

partition_list.each { |p|
    raise "#{p} is missing from partition list"  unless mount_hash.has_key?(p) 
}

