#!/usr/bin/ruby
def getsettings(settings_file)
  if File.file?(settings_file) 
    settings = YAML.load_file(settings_file)
  else
     raise "Settings yaml file does not exist or is not a file."
  end
end

def getjson(json_file)
  if File.file?(json_file) 
    f = File.open(json_file,'r')
    json = String.new
    f.each {|line|
      unless  line[0] == '#'
        json = json + line
      end
    }
    f.close
    json
  else
    raise "JSON file does not exist or is not a file."
  end
end

require 'json'
require 'yaml'

json_tmp=ARGV[0]
setting_yaml=ARGV[1]

settings = getsettings setting_yaml 
json = getjson json_tmp 

json.gsub!(/^#*$/,'')

settings.each { |key, value|
  json.gsub!(key,value)
}

File.open('simp.json','w') do |h| 
     h.write json
     h.close
end

