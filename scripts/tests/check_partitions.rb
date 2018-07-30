#! /usr/bin/env ruby

puts `df -h`

partition_list = [ '/var','/var/log','/var/log/audit', '/' ]
x = %x(df -P)
y = x.split("\n")

mount_hash = Hash.new
y.each{|m|
  mount = m.split(' ')
  mount_hash["#{mount[5]}"] = mount[0]
}

partition_list.each { |p|
    raise "#{p} is missing from partition list"  unless mount_hash.has_key?(p)
}

puts 'Expected partitions found'

