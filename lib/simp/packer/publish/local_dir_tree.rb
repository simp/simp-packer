require 'fileutils'
require 'json'

module Simp
  module Packer
    module Publish
      # Create and manage a local (atlus-like) directory tree for vagrant boxes
      class LocalDirTree
        include FileUtils

        attr_accessor :verbose
        def initialize(base_dir)
          @base_dir = base_dir
          @verbose  = false
        end

        def publish(box_data, copy = false)
          username = box_data['username']
          name     = box_data['name']
          version  = box_data['versions'].first['version']
          provider = box_data['versions'].first['providers'].first['name']
          box_file_src = box_data['versions'].first['providers'].first['url']
          box_file_dest = File.expand_path(File.join(@base_dir, username, 'boxes', name, 'versions', version, "#{provider}.box"))
          box_json_dest = File.expand_path(File.join(@base_dir, username, 'boxes', name, 'versions', version, "#{provider}.json"))
          box_dir = File.dirname box_file_dest
          boxname_json_dest = File.expand_path(File.join(@base_dir, username, 'boxes', "#{name}.json"))

          # Below this line: local file stuff
          mkdir_p box_dir, verbose: @verbose
          box_data['versions'].first['providers'].first['url'] = "file://#{box_file_dest}"
          if copy
            migrate = lambda{ |src,dst,verbose=true| FileUtils::cp src, dst, verbose: verbose }
          else
            migrate = lambda{ |src,dst,verbose=true| FileUtils::mv src, dst, verbose: verbose }
          end
          src_path = box_file_src.sub(%r{^file://},'')
          migrate.call src_path, box_file_dest

          # copy Vagrantfile erb templates (use with `vagrant init BOX --template VAGRANT_ERB_FILE`)
          Dir[File.expand_path('../Vagrantfile*.erb',src_path)].each do |v|
            migrate.call v, File.dirname(box_file_dest), @verbose
          end
          write_box_json(box_json_dest, box_data)

          # this is the latest top-level box
          # TODO: This should eventually scan/collect/prune all box_json_dest
          #       files for this boxname and aggregate them here.
          write_box_json(boxname_json_dest, box_data)
        end

        def write_box_json(box_json_path, box_metadata)
          # write box metadata file
          puts "\n\nWriting box metadata file to:"
          puts "\n   #{box_json_path}\n\n"
          File.open(box_json_path, 'w') do |f|
            f.puts JSON.pretty_generate(box_metadata)
          end

          puts_vagrant_init_message(box_metadata['box_tag'], box_json_path)
        end

        # construct a relevant `vagrant init`
        def puts_vagrant_init_message(box_tag, box_json_path)
          require 'pathname'
          pn = Pathname.new(box_json_path)
          vf_box_url = if pn.absolute?
                         "file://#{pn.realpath}"
                       elsif pn.realpath.relative_path_from(Pathname.getwd).to_s =~ %r{^\..}
                         "file://#{pn.realpath}"
                       else
                         "file://./#{pn}"
                       end
          vagrant_template_path = File.join(File.dirname(box_json_path), 'Vagrantfile.erb')
          extra = File.file?(vagrant_template_path) ? "--template '#{vagrant_template_path}'" : ''
          puts "vagrant init #{box_tag} #{vf_box_url} #{extra}".strip
        end
      end
    end
  end
end
