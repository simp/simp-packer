module Simp
  module Packer
    module Config
      # Renders a Vagrantfile from a template
      #
      #   This is useful to render both `Vagrantfile` and `Vagrantfile.erb` files
      #
      class SimpjsonfileWriter
        def initialize(settings,basedir)
          @template_dir = File.join(basedir, 'templates')
          @settings = settings

        end

        # Returns the rendered Vagrantfile content
        # @return [String] Rendered Vagrantfile text
        def render templatename
          content = File.read(File.join(@template_dir,templatename))
          t = ERB.new(content, nil, '-')
          t.result(binding)
        end

      end
    end
  end
end
