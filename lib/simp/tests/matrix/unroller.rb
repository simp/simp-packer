module Simp
  module Tests
    module Matrix
      # The `Simp::Tests::Matrix::Unroller` mixin provides classes with tools
      #   to "unroll" compact matrix specifications
      module Unroller
        # Expands a list of compact matrix specifications into an
        #   easy-to-iterate list of each `:key => value` combination.
        #
        # * Each element in the **matrix specification** is a String that
        #   describes a key with _multiple_ values, in the format
        #   `"key=value1[:value2...]`.
        # * "Unrolling" expands each specification into a list of
        #   key/_single_-value pairs and returns all combinations of each
        #   key/value.
        # * When multiple specifications are provided for a single key, the
        #   last one is used.
        #
        # @param matrix [Array<String>] list of matrix specification Strings
        #   Each element specifies a key and 1-n values in the format
        #
        # @return [Array<Hash>] the unrolled matrix as (symbolized) key/value pairs
        #
        # @example Basic usage
        #   include Simp::Tests::Matrix::Unroller
        #
        #   iterations = unroll ['a=on:off', 'b=foo:bar:baz'] #=>
        #   # [
        #   #   {:a=>'on',  :b=>'foo'},
        #   #   {:a=>'off', :b=>'foo'},
        #   #   {:a=>'on',  :b=>'bar'},
        #   #   {:a=>'off', :b=>'bar'},
        #   #   {:a=>'on',  :b=>'baz'},
        #   #   {:a=>'off', :b=>'baz'}
        #   # ]
        #
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
