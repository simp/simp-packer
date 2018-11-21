module Simp
  module Packer
    module Config
      # Renders a Vagrantfile from a template
      #
      #   This is useful to render both `Vagrantfile` and `Vagrantfile.erb` files
      #
      class VagrantfileWriter
        def initialize(name, ip, mac, nw, template)
          @name = name
          @ipaddress = ip
          @mac = mac
          @nw = nw
          @template = template
        end

        # Returns the rendered Vagrantfile content
        # @return [String] Rendered Vagrantfile text
        def render
          require 'erb'
          ERB.new(@template).result(binding)
        end
      end
    end
  end
end
