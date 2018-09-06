require 'rake/clean'

CLEAN << FileList.new('puppet/modules/*/spec/fixtures')

task :clean do
  require 'find'
  Find.find('puppet', 'assets', 'scripts', 'files') do |path|
    File.unlink(path) if File.symlink? path
  end
end
