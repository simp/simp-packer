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
    desc <<MSG
Install vagrant box into a local directory tree, generate version metadata

This moves a vagrant .box file into a directory tree that acts more-or-less
like VagrantCloud/Atlus' box API, and generates a

* tree_dir             Path to the top level of a vagrantcloud-like directory
                       structure.  This path will be created if it does not
                       exist.
* simp_iso_json_file   Path .json file generated with box ISO's SIMP build:auto
* box_path             Path to the generated Vagrant .box file
* copy                 'copy' or 'move'; action to publish .box file
                       (default: move)
MSG
    task :local, [:tree_dir, :simp_iso_json_file, :box_path, :copy] do |_t, args|
      args.with_defaults(:copy => 'move')
      unless ['move','copy'].include?(args.copy.to_s)
        raise "\nERROR: :copy was '#{args.copy}'; must be one of: 'move', 'copy'\n\n"
      end
      converter = Simp::Packer::VarsJsonToVagrantBoxJson.new(args.simp_iso_json_file)
      box_data  = converter.vagrant_box_json(args.box_path)
      dir_tree  = Simp::Packer::Publish::LocalDirTree.new(args.tree_dir)
      dir_tree.publish(box_data, args.copy.to_s == 'copy')
    end
  end
end
