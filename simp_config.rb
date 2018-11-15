#!/usr/bin/env ruby
$LOAD_PATH << File.expand_path('lib', __dir__)
require 'simp/packer/config_prepper'

# Usage <scriptname> workingdir testdir
Simp::Packer::ConfigPrepper.new(ARGV[0], ARGV[1], __dir__).run
