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

        simp_box_flavors = infer_simp_flavors(@vars_json_data)

        @options = options.dup
        @options[:org]  ||= 'simpci'
        @options[:name] ||= "server-#{simp_box_flavors}"
        @options[:desc] ||= "SIMP server #{simp_box_flavors}"
      end

      # Convert the data from a simp-packer `vars.json` to Vagrant-consumable
      #   metadata that includes version information and box location
      #
      # @param vagrantbox_path [String] path to Vagrant .box file
      # @param options [Hash] optional metadata overrides
      #
      # @option options [String]  :version       Defaults to the `.box` file's File.mtime (%Y%m%d.%H%M%S)
      # @option options [String]  :status        (active)
      # @option options [Boolean] :is_private    (false)
      # @option options [Integer] :downloads     (0)
      # @option options [String]  :provider_name (virtualbox)
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

        {
          'tag'                  => "#{@options[:org]}/#{@options[:name]}",
          'name'                 => @options[:name],
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

      # Most of the methods below this line is effing magic used to infer
      # properties about a SIMP box based on the vars.json that was used to
      # build it.
      #
      # @todo Add more properties to vars.json in `build:auto`, so the simphack
      #   fragments aren't needed.
      def infer_simp_flavors(vars_json_data)
        box_simp_release = vars_json_data['box_simp_release']
        fragment = semver_fragment(box_simp_release)
        if (simphack_fragment = semver_simpbox_hack_checks(vars_json_data))
          fragment = simphack_fragment
        end
        ensure_semver(fragment)
      end

      # Magic method to get the ACTUAL SIMP ISO version out of the vars.json
      #
      # This hack is necessary because of the strange data that currently comes
      # back with the simp-metadata-based ISO builds.
      #
      def semver_simpbox_hack_checks(vars_json_data)
        iso_name = File.basename(vars_json_data['iso_url'])
        str = iso_name.sub(%r{^SIMP-}, '').sub(%r{\.iso$}, '').gsub(%r{-x86_64}, '.x86-64').tr('_', '-')
        if str == semver_fragment(str)
          str
        else
          false
        end
      end

      # Make SURE a String is SemVer (but if it's already SemVer, leave it alone)
      #
      # @note This ought to be a last resort, as it translates things like "6.X"
      #       into "6.0.0-X".   If you have any more tricks up your sleeve that
      #       could infer a more specific version, try them first!
      #
      # @param fragment [String] A SemVer fragment to evaluate
      # @return [String] A valid SemVer String.  If `fragment` was already
      #         valid SemVer, it will be returned unchanged.
      #
      def ensure_semver(fragment)
        if semver_xyz_count(fragment) < 3
          str = semver_xyz_match(fragment)
          suffix = box_simp_release.sub(%r{^#{str}\.?}, '').sub(%r{^(.+)$}, '-\1')
          fragment = "#{pad_missing_semver_xyz_sections(fragment)}#{suffix}"
        end
        fragment
      end

      # Return as much of valid SemVer (including suffixes for pre-release and
      #   build metadata as possible) as a String contains
      #
      # SemVer 2.0.0 regex, tested at http://rubular.com/r/s9QAkciFhz
      #
      # @param str [String] A SemVer fragment to evaluate
      # @return [String] As much of a valid SemVer String as there is
      def semver_fragment(str)
        semver2_0_0ish_regex = %r{^(((?:\d+\.?){2}\d)(?:[\-+][a-zA-Z0-9\-.]*?$)|((?:\d+\.?){0,2}\d))}
        semver2_0_0ish_regex.match(str).captures.first
      end

      # Return as much of a SemVer X.Y.Z number as a String contains
      #
      # @param str [String] A SemVer fragment to evaluate
      # @return [String] Matching SemVer X.Y.Z sections
      def semver_xyz_match(str)
        semver2_0_0ish_xyz_regex = %r{^(((?:\d+\.?){0,2}\d))}
        matches = semver2_0_0ish_xyz_regex.match(str.to_s)
        matches.nil? ? '' : matches.captures.first
      end

      # Count number of SemVer XYZ sections
      #
      # @param str [String] A SemVer fragment to evaluate
      # @return [Integer] Number of SemVer X.Y.Z sections
      def semver_xyz_count(str)
        xyz_fragment = semver_xyz_match(str)
        xyz_fragment.empty? ? 0 : (xyz_fragment.count('.') + 1)
      end

      # Use zeros to pad any missing SemVer X.Y.Z numbers
      def pad_missing_semver_xyz_sections(str)
        xyz_str = semver_xyz_match(str)
        count = semver_xyz_count(xyz_str)
        (3 - count).times { xyz_str += '.0' }
        xyz_str
      end
    end
  end
end
