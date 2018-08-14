#! /usr/bin/env ruby
# Test to see if expect partitions exist, fail if they don't
EXPECTED_PARTITIONS = ['/var', '/var/log', '/var/log/audit', '/'].sort
puts `findmnt --df`

mounts     = `findmnt --noheadings --raw`.split("\n").map { |line| line.split(' ')[0] }

EXPECTED_PARTITIONS.each do |p|
  unless mounts.include?(p)
    raise "ERROR: The expected partition '#{p}' is not mounted"
  end
end

puts '-----------------------------------',
     'SUCCESS: Found expected partitions:',
     EXPECTED_PARTITIONS.each { |p| puts p },
     '-----------------------------------'
