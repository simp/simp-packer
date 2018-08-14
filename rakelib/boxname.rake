require 'json'
module Simp
  module Converter
    class VarsJsonToVagrantBoxJson
      def initialize( vars_json_path )
        JSON.parse File.read(vars_json_path)
        @vars_json_data = JSON.parse File.read(vars_json_path)
      end

      def vagrant_box_json( vagrantbox_path, box_json_path='boxname.json' )
        simp_box_version  = infer_simp_version(@vars_json_data)
        datetime_fragment = Time.now.strftime('%Y%m%d.%H%M%S')
        box_version = "#{simp_box_version}.#{datetime_fragment}"
        vars_simp_release = @vars_json_data['box_simp_release']
        z_date = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
        box_checksum = `sha256sum "#{vagrantbox_path}"`.split(/ +/).first
        box_name = "simpci/server-#{simp_box_version}"
        box_url = "file://#{vagrantbox_path}"

        box_metadata = {
          'description'       => "SIMP server #{vars_simp_release}",
          'short_description' => "SIMP server #{vars_simp_release}",
          'name' => box_name,
          'versions' => [{
            'version' => box_version,
            'status' => 'active',
            'description_html' => nil,
            'description_markdown' => nil,
            'created_at' => z_date,
            'updated_at' => z_date,
            'providers' => [{
              'checksum_type' => 'sha256',
              'checksum'      => box_checksum,
              'name'          => 'virtualbox',
              'url'           => box_url,
            }]
          }],
        }
      box_metadata_json = JSON.pretty_generate box_metadata
puts box_metadata.to_yaml
puts  box_metadata_json

        # write box metadata file
        puts "Writing '#{box_json_path}...'"
        File.open(box_json_path, 'w') {|f| f.puts box_metadata_json }
        require 'pathname'

        # construct a relevant `vagrant init`
        pn = Pathname.new(box_json_path)
        if pn.absolute?
          vf_box_url = "file://#{pn.realpath.to_s}"
        elsif pn.realpath.relative_path_from(Pathname.getwd).to_s =~ /^\../
          vf_box_url = "file://#{pn.realpath.to_s}"
        else
          vf_box_url = "file://./#{pn.to_s}"
        end
        puts "vagrant init #{box_name} #{vf_box_url}"
      end

      def infer_simp_version(vars_json_data)
        box_simp_release = vars_json_data['box_simp_release']
        fragment = semver_fragment(box_simp_release)
        if simphack_fragment = semver_simpbox_hack_checks(vars_json_data)
          fragment = simphack_fragment
        end
        fragment = ensure_semver(fragment)
      end


      # Magic to get the ACTUAL SIMP ISO version out of the vars.json
      #
      # This hack is necessary because of the strange data coming back with the
      # simp-metadata-based ISO builds.
      #
      def semver_simpbox_hack_checks(vars_json_data)
        iso_name = File.basename(vars_json_data['iso_url'])
        str = iso_name.sub(/^SIMP-/,'').sub(/\.iso$/,'').gsub(/-x86_64/,'.x86-64').gsub(/_/,'-')
        if (str == semver_fragment(str))
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
          suffix = box_simp_release.sub(/^#{str}\.?/,'').sub(/^(.+)$/,'-\1')
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
        semver2_0_0ish_regex=/^(((?:\d+\.?){2}\d)(?:[\-+][a-zA-Z0-9\-.]*?$)|((?:\d+\.?){0,2}\d))/
        semver2_0_0ish_regex.match(str).captures.first
      end

      # Return as much of a SemVer X.Y.Z number as a String contains
      #
      # @param str [String] A SemVer fragment to evaluate
      # @return [String] Matching SemVer X.Y.Z sections
      def semver_xyz_match(str)
        semver2_0_0ish_xyz_regex = /^(((?:\d+\.?){0,2}\d))/
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
        count = semver_xyz_count(str)
        xyz_str = semver_xyz_match(str)
        count = semver_xyz_count(xyz_str)
        (3-count).times { xyz_str += '.0' }
        xyz_str
      end
    end
  end
end


namespace :vagrant do
  desc <<BOXNAME_DESCRIPTION
Create boxname.json from SIMP ISO .json file

Example:
  rake vagrant:boxname["$PWD/test-el7-v11/vars.json","$PWD/test-el7-v11/OUTPUT/SIMP6.X-CENTOS7-FIPS.box"]
BOXNAME_DESCRIPTION

  task :boxname, [:simp_iso_json_file,:vagrantbox_path]  do |t, args|
    args.with_defaults( :simp_iso_json_file => 'vars.json' )

    converter = Simp::Converter::VarsJsonToVagrantBoxJson.new(args.simp_iso_json_file)
    converter.vagrant_box_json(args.vagrantbox_path)
  end
end
