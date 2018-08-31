require 'json'

module Simp
  module Packer
    class VarsJsonToVagrantBoxJson
      def initialize(vars_json_path)
        JSON.parse File.read(vars_json_path)
        @vars_json_data = JSON.parse File.read(vars_json_path)
      end

      def vagrant_box_json(vagrantbox_path, _box_json_path = 'boxname.json')
        utc_time         = Time.now.utc
        utc_z_date       = utc_time.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
        utc_hhmmss_hms   = utc_time.strftime('%Y%m%d.%H%M%S')
#        box__z_date         = File.mtime(vagrantbox_path).strftime('%Y%m%d.%H%M%S')
#        box__utc_hhmmss_hms = File.mtime(vagrantbox_path).strftime('%Y%m%d.%H%M%S')
        simp_box_flavors = infer_simp_flavors(@vars_json_data)

require 'pry'; binding.pry
        unless File.file? vagrantbox_path
          raise Errno::ENOENT, "ERROR: Can't find .box file at '#{vagrantbox_path}'"
        end

        warn "Calculating sha256sum of '#{vagrantbox_path}'..."
        box_checksum = %x(sha256sum "#{vagrantbox_path}").split(%r{ +}).first
        box_metadata = vagrant_box_json_entry(
          'simpci',
          "server-#{simp_box_flavors}",
          utc_hhmmss_hms.to_s,
          "SIMP server #{simp_box_flavors}",
          "file://#{vagrantbox_path}",
          utc_z_date,
          utc_z_date,
          box_checksum
        )
        box_metadata
      end

      # Returns a versioned box metadata data structure used by sevices like
      # Vagrant Cloud.
      #
      # @see https://www.vagrantup.com/docs/boxes/format.html#box-metadata
      #   Vagrant Box Metadata structure
      # @see https://www.vagrantup.com/docs/vagrant-cloud/api.html#read-a-box
      #   Vagrant Cloud API documentation for "Read a box"
      #
      # @return [Hash]
      def vagrant_box_json_entry(
        user_name,
        box_name,
        box_version,
        description,
        box_url,
        created_at,
        updated_at,
        box_checksum,
        checksum_type = 'sha256',
        status        = 'active',
        provider_name = 'virtualbox',
        is_private    = false,
        downloads     = 0
      )
        box_tag = "#{user_name}/#{box_name}"
        box_metadata = {
          'tag'                  => box_tag,      # "myuser/test"
          'name'                 => box_name,     # "test"
          'username'             => user_name,    # 'myuser"
          'created_at'           => created_at,   # '2017-10-20T14:19:59.842Z"
          'updated_at'           => updated_at,   # "2017-10-20T15:23:53.363Z"
          'private'              => is_private,
          'downloads'            => downloads,
          'short_description'    => description,
          'description_markdown' => description,
          'description_html'     => "<p>#{description}</p>",
          'versions'             => [{
            'version'              => box_version,
            'status'               => status,
            'description_html'     => "<p>#{description}</p>",
            'description_markdown' => description,
            'created_at'           => created_at,
            'updated_at'           => updated_at,
            'providers'            => [{
              'checksum_type' => checksum_type,
              'checksum'      => box_checksum,
              'name'          => provider_name,
              'url'           => box_url
            }]
          }]
        }
        box_metadata
      end

      # Most of the methods below this line is effing magic used to infer
      # properties about a SIMP box based on the vars.json that was used to
      # build it.
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

      # Make SURE a String is SemVer (but if it's alredy SemVer, leave it alone)
      #
      # NOTE: This ought to be a last resort, as it translates things like #
      #       "6.X" into "6.0.0-X".   If you have any more up your sleeve that
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

      # Return as much of valid SemVer (including suffixes for pre-relase and
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
