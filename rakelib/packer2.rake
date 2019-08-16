namespace :packer do
  desc <<-DESC.gsub(%r{^    }, '')
    Validates simp.json[.template] and var-files

    Unlike `packer validate FILE`, this will work on `simp.json.template` file
    that contains comments.

    Arguments (both optional):
    * json           (Default: simp.json.erb, ENV: SIMP_PACKER_json_file)
                     Name of .json or .json.template file to validate.  If no path is
                     included, `<simp-packer>/template/` will be assumed.

    * vars_file      (Default: simp.json.template, ENV: SIMP_PACKER_json_file)
                     Path to a specific -vars-file to include in validation.
                     If no vars_file is given, a minimal set of spurious vars
                     will be provided by the command line for `iso_url`,
                     `iso_checksum`, and `iso_checksum_type`.
   * settings_file   A file with a json hash of settings.

  DESC
  task :validate, [:json, :vars_file] do |_t, args|
    args.with_defaults(json: ENV['SIMP_PACKER_json_file'] || 'simp.json.erb')
    args.with_defaults(vars_json: ENV['SIMP_PACKER_vars_json_file'] || nil)
    args.with_defaults(settings_file: ENV['SIMP_PACKER_settings_file'] || nil)
    json = args.json
    json = File.expand_path(json, "#{__dir__}/../templates") if File.basename(json) == json
    raise "ERROR: json file '#{json}' not found.  (ENV: SIMP_PACKER_json_file)" unless File.exist?(json)
    text = File.read(json).gsub(%r{^\s*//.*(?:\r|\n)?}, '')
    if settings_file.nil? then 
      in_settings = { "os_ver" => '7' }
    else 
       raise "ERROR: could not read settings file #{settings_file}" unless File.exist?(settings_file)
       in_settings  = JSON.parse(File.read(settings_file))['settings']
    end
    require 'tmpdir'
    basedir = "#{__dir__}/.."
    Dir.mktmpdir 'simp-packer-validate' do |dir|
      prepper =  Simp::Packer::Config::Prepper.new(dir,dir,basedir)
      settings = prepper.default_settings.merge(in_settings)
      simp_json = File.join(dir, 'simp.json')
      simp_json_data = Simp::Packer::Config::SimpjsonfileWriter.new(settings,basedir).render json
      File.open(simp_json, 'w') { |f| f.puts text }
      extra_args = "-var 'iso_url=#{dir}' -var 'iso_checksum_type=sha256' -var 'iso_checksum=x'"
      extra_args = "-var-file '#{args.vars_file}'" if args.vars_file
      sh 'packer --version'
      sh "packer validate #{extra_args} '#{simp_json}'"
    end
  end
end
