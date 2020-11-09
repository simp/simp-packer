# frozen_string_literal: true

require 'json'

module Simp
  module Packer
    #
    # Convert the data from a simp-packer `vars.json` to Vagrant-consumable
    #   metadata that resembles the Vagrant Cloud API.
    #
    # @note The `vars.json` file is used by simp-packer to build a Vagrant .box
    #       from a SIMP ISO.  A `.json` file created in this format during each
    #       SIMP ISO build (created by the task `rake build:auto`).
    #
    # @see https://www.vagrantup.com/docs/boxes/format.html#box-metadata
    #   Vagrant Box Metadata structure
    # @see https://www.vagrantup.com/docs/vagrant-cloud/api.html#read-a-box
    #   Vagrant Cloud API documentation for "Read a box"
    #
    class VarsJsonToVagrantBoxJson
      def initialize(vars_json_path, options = {})
        JSON.parse File.read(vars_json_path)
        @vars_json_data = JSON.parse File.read(vars_json_path)

        simp_box_flavors = [
          @vars_json_data['box_simp_release'],
          "el#{@vars_json_data['dist_os_maj_version']}",
          @vars_json_data['dist_os_flavor'],
          @vars_json_data['dist_os_version'],
          "x86_64", # TODO: add architecture to `rake build:auto`-genned vars.json
        ].join('-')

        @options = options.dup
        @options[:org] ||= 'simpci'
        @options[:name] ||= "server-#{simp_box_flavors}"
        @options[:desc] ||= "SIMP server #{simp_box_flavors}"
      end

      # Convert the data from a simp-packer `vars.json` to Vagrant-consumable
      #   metadata that includes version information and box location
      #
      # @param vagrantbox_path [String] path to Vagrant .box file
      # @param options [Hash] optional metadata overrides
      #
      # @option options [String]        :version       Defaults to the `.box` file's File.mtime (%Y%m%d.%H%M%S)
      # @option options [String]        :status        (active)
      # @option options [Boolean]       :is_private    (false)
      # @option options [Integer]       :downloads     (0)
      # @option options [String]        :provider_name (virtualbox)
      # @option options [Array<String>] :flavors       Extra descriptive strings to tack onto box name
      #
      # @see https://www.vagrantup.com/docs/boxes/format.html#box-metadata
      #   Vagrant Box Metadata structure
      # @see https://www.vagrantup.com/docs/vagrant-cloud/api.html#read-a-box
      #   Vagrant Cloud API documentation for "Read a box"
      #
      # @return [Hash] Vagrant box metadata with version information
      def vagrant_box_json(
        vagrantbox_path,
        options = {}
      )
        unless File.file? vagrantbox_path
          raise Errno::ENOENT, "ERROR: Can't find .box file at '#{vagrantbox_path}'"
        end

        created_at = File.mtime(vagrantbox_path).strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
        updated_at = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')

        warn "Calculating sha256sum of '#{vagrantbox_path}'..."
        require 'digest'
        box_checksum = Digest::SHA256.file(vagrantbox_path).hexdigest
        box_name = options[:name] || @options[:name]
        flavors  = options[:flavors] || []
        unless flavors.empty?
          box_name += "-#{flavors.join('-')}"
        end

        {
          'tag'                  => "#{@options[:org]}/#{box_name}",
          'name'                 => box_name,
          'username'             => @options[:org],
          'created_at'           => created_at,
          'updated_at'           => updated_at,
          'private'              => options[:is_private] || false,
          'downloads'            => options[:downloads] || 0,
          'short_description'    => @options[:desc],
          'description_markdown' => @options[:desc],
          'description_html'     => "<p>#{@options[:desc]}</p>",
          'versions'             => [{
            'version'              => options[:version] || File.mtime(vagrantbox_path).strftime('%Y%m%d.%H%M%S'),
            'status'               => options[:status] || 'active',
            'description_html'     => "<p>#{@options[:desc]}</p>",
            'description_markdown' => @options[:desc],
            'created_at'           => created_at,
            'updated_at'           => updated_at,
            'providers'            => [{
              'checksum_type' => 'sha256',
              'checksum'      => box_checksum,
              'name'          => options[:provider_name] || 'virtualbox',
              'url'           => File.expand_path(vagrantbox_path)
            }]
          }]
        }
      end
    end
  end
end
