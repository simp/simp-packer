namespace :packer do
  desc <<-DESC.gsub(%r{^    }, '')
    Validates simp.json[.template] and var-files

    Unlike `packer validate FILE`, this will work on `simp.json.template` file
    that contains comments.

    Arguments (both optional):
    * template_name  The name of the template.

    * template_dir   The FQDN directory of your templates.
                     (Default: simp-packer/templates ENV: SIMP_PACKER_json_file)
                     The basename must be called templates.

    * vars_file      (Default: simp.json.template, ENV: SIMP_PACKER_json_file)
                     Path to a specific -vars-file to include in validation.
                     If no vars_file is given, a minimal set of spurious vars
                     will be provided by the command line for `iso_url`,
                     `iso_checksum`, and `iso_checksum_type`.
   * settings_file   A file with a json hash of settings.

  DESC
  task :validate, [:template_name, :template_dir, :vars_file, :settings_file] do |_t, args|
    args.with_defaults(template_name: ENV['SIMP_PACKER_template_name'] || 'simp.json.erb')
    args.with_defaults(template_dir: ENV['SIMP_PACKER_template_dir'] || "#{__dir__}/../templates")
    args.with_defaults(vars_json: ENV['SIMP_PACKER_vars_json_file'] || nil)
    args.with_defaults(settings_file: ENV['SIMP_PACKER_settings_file'] || nil)
    settings_file = args.settings_file
    vars_file = args.vars_file
    json = File.join(args.template_dir, args.template_name)

    raise "ERROR: json file '#{}' not found.  (ENV: SIMP_PACKER_json_file)" unless File.exist?(json)
    if settings_file.nil? then
      in_settings = { "os_ver" => '7' }
    else
       raise "ERROR: could not read settings file #{settings_file}" unless File.exist?(settings_file)
       in_settings  = JSON.parse(File.read(settings_file))['settings']
    end
    require 'tmpdir'
    Dir.mktmpdir 'simp-packer-validate' do |dir|
      basedir = File.dirname(File.dirname(json))
      templatename = File.basename(json)
      prepper =  Simp::Packer::Config::Prepper.new(dir,dir,basedir)
      settings = prepper.default_settings.merge(in_settings)
      simp_json = File.join(dir, 'simp.json')
      simp_json_data = Simp::Packer::Config::SimpjsonfileWriter.new(settings,basedir).render templatename
      File.open(simp_json, 'w') { |f| f.puts simp_json_data }
      extra_args = "-var 'iso_url=#{dir}' -var 'iso_checksum_type=sha256' -var 'iso_checksum=x'"
      extra_args = "-var-file '#{args.vars_file}'" if args.vars_file
      sh 'packer --version'
      sh "packer validate #{extra_args} '#{simp_json}'"
    end
  end
end
