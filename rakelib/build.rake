namespace :simp do
  namespace :packer do
    desc <<-DESC.gsub(%r{^    }, '')
      Validates simp.json[.template] and var-files.  WARNING: Does NOT publishi .box to Vagrant dirtree.

      * vars_json      (ENV: SIMP_PACKER_json_file) Path to a specific packer
                       vars-file to use in the build.

     * packer_yaml     (Optional) Path to packer.yaml file
                       (Default: generic headless centos7/packer.yaml,
                        ENV: SIMP_PACKER_packer_yaml_file)

     * simp_conf_yaml  (Optional) Path to simp_conf.yaml file
                       (Default: Generic FIPS-enabled simp_conf.yaml,
                        ENV: SIMP_PACKER_simp_conf_yaml_file)

     * test_dir        (Optional) Path to test directory
                       (Default: "simp-packer-build-<YYYYddmm-HHMMSS>",
                        ENV: SIMP_PACKER_test_dir)
    DESC
    task :build, [:vars_json, :packer_yaml, :simp_conf_yaml, :test_dir] do |t, args|
      require 'simp/packer/build/runner'
      date = Time.now.strftime('%Y%m%d-%H%M%S')
      unless ENV['SIMP_PACKER_vars_json_file']
        msg = ['ERROR:  You must supply the path to a :vars_json file:']
        msg << "\nrake #{t.name_with_args}\n"
        msg += t.full_comment.split("\n").map { |x| "    #{x}" }
        msg << "\n"

        raise  msg.join("\n") unless args.vars_json
        args.with_defaults(vars_json: ENV['SIMP_PACKER_vars_json_file'])
      end
      args.with_defaults(packer_yaml: ENV['SIMP_PACKER_packer_yaml_file'] || \
                         'lib/simp/packer/files/configs/centos7/packer.yaml')
      args.with_defaults(simp_conf_yaml: ENV['SIMP_PACKER_simp_conf_yaml_file'] || \
                         'lib/simp/packer/files/configs/centos7/simp_conf.yaml')
      args.with_defaults(test_dir: ENV['SIMP_PACKER_test_dir'] || "simp-packer-build-#{date}")

      packer_build_runner = Simp::Build::Packer::Runner.new(args.test_dir)
      packer_build_runner.prep(
        args.vars_json,
        args.simp_conf_yaml,
        args.packer_yaml
      )
      packer_build_runner.run
    end
  end
end
