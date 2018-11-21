module Simp
  module Packer
    module Build
      module MatrixUnroller
        # Returns matrix, unrolled as an Array of Hashes with symbolized keys
        def unroll(matrix)
          tiers = matrix.map do |cfg|
            pair = cfg.split('=')
            key  = pair.first
            pair.last.split(':').map { |v| { key.to_sym => v } }
          end
          tiers.reduce([]) do |list, values|
            if list.empty?
              list = values
            else
              new = []
              values.each { |x| list.each { |y| new << y.merge(x) } }
              new
            end
          end
        end
      end
    end
  end
end
