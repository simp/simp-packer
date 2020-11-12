# frozen_string_literal: true

module VarsJsonHelpers
  # Generate a minimal data structure to mock a v1.0.0 vars.json for a SIMP ISO
  def mock_vars_json_data(os_maj_rel:, iso_file_path:, data: {})
    mocked_data = {
      'simp_vars_version'   => '1.0.0',
      'box_simp_release'    => '6.X',
      'box_distro_release'  => 'FIXME: NOT_SET_YET_IN_MOCKED_HELPER',
      'new_password'        => 'L0oSrP@ssw0r!L0oSrP@ssw0r!L0oSrP@ssw0r!',
      'dist_os_flavor'      => 'CentOS',
      'dist_os_version'     => 'FIXME: NOT_SET_YET_IN_MOCKED_HELPER',
      'dist_os_maj_version' => (os_maj_rel.to_s).match(%r{\d+}).to_a.first
    }

    # Provide default ISO checksum if data['iso_url'] or iso_file_path is set
    # to an existing file.  This will be replaced if the same keys are set in
    # data[], but ensures correct mocked_data exist when they are missing
    default_iso_path = File.exist?(data['iso_url'].to_s.sub(%r{^file://}, '')) ? data['iso_url'] : iso_file_path
    default_iso_path.to_s.sub!(%r{^file://}, '')
    if File.exist?(default_iso_path)
      mocked_data.merge!({
        'iso_url'           => "file://#{default_iso_path}",
        'iso_checksum'      => Digest::SHA256.hexdigest(default_iso_path),
        'iso_checksum_type' => 'sha256'
      })
    end

    mocked_data.merge(data)
  end
end
