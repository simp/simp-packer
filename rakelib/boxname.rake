require 'simp/packer/vars_json_to_vagrant_box_json'
require 'simp/packer/publish/local_dir_tree'

namespace :vagrant do
  desc <<-BOXNAME_DESCRIPTION.gsub(%r{^ {4}}, '')
    Create boxname.json from SIMP ISO .json file

    Example:
      rake vagrant:boxname["$PWD/test-el7-v11/vars.json","$PWD/test-el7-v11/OUTPUT/SIMP6.X-CENTOS7-FIPS.box"]
  BOXNAME_DESCRIPTION
  task :boxname, [:simp_iso_json_file, :vagrantbox_path] do |_t, args|
    args.with_defaults(:simp_iso_json_file => 'vars.json')
    converter = Simp::Packer::VarsJsonToVagrantBoxJson.new(args.simp_iso_json_file)
    converter.vagrant_box_json(args.vagrantbox_path)
  end

  namespace :publish do
    desc 'Install vagrant box into a local directory tree'
    task :local, [:tree_dir, :simp_iso_json_file, :box_path] do |_t, args|
      converter = Simp::Packer::VarsJsonToVagrantBoxJson.new(args.simp_iso_json_file)
      box_data = converter.vagrant_box_json(args.box_path)
      dir_tree = Simp::Packer::Publish::LocalDirTree.new(args.tree_dir)
      dir_tree.publish(box_data)
    end
  end
end
