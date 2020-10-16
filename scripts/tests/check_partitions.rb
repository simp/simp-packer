#! /usr/bin/env ruby
# frozen_string_literal: true

# Test to see if expect partitions exist, fail if they don't
EXPECTED_PARTITIONS = ['/var', '/var/log', '/var/log/audit', '/'].sort
puts `df -h | grep -v tmpfs`

mounts = `findmnt --noheadings --raw`.split("\n").map { |line| line.split(' ')[0] }

EXPECTED_PARTITIONS.each do |p|
  raise "ERROR: The expected partition '#{p}' is not mounted" unless mounts.include?(p)
end

puts '-----------------------------------',
     'SUCCESS: Found expected partitions:',
     EXPECTED_PARTITIONS.each { |p| puts p },
     '-----------------------------------'
