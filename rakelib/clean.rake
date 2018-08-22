require 'rake/clean'

CLEAN << FileList.new('puppet/modules/*/spec/fixtures')
