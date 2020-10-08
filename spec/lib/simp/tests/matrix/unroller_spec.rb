require 'simp/tests/matrix/unroller'
require 'spec_helper'

describe Simp::Tests::Matrix::Unroller do
  describe '#unroll' do
    before :all do
      class Foo
        include Simp::Tests::Matrix::Unroller
      end
      @obj = Foo.new
    end

    it 'unrolls x1 ordered matrix specifications' do
      matrix_specification = ['a=foo:bar:baz']
      expect(@obj.unroll(matrix_specification)).to eq [
        { a: 'foo' },
        { a: 'bar' },
        { a: 'baz' },
      ]
    end

    it 'unrolls x2 ordered matrix specifications' do
      matrix_specification = ['a=on:off', 'b=foo:bar:baz']
      expect(@obj.unroll(matrix_specification)).to eq [
        { a: 'on',  b: 'foo' },
        { a: 'off', b: 'foo' },
        { a: 'on',  b: 'bar' },
        { a: 'off', b: 'bar' },
        { a: 'on',  b: 'baz' },
        { a: 'off', b: 'baz' },
      ]
    end

    it 'unrolls x3 ordered matrix specifications' do
      matrix_specification = ['a=on:off', 'b=foo:bar:baz', 'c=x:y:z']
      expect(@obj.unroll(matrix_specification)).to eq [
        { a: 'on', b: 'foo', c: 'x' },
        { a: 'off', b: 'foo', c: 'x' },
        { a: 'on', b: 'bar', c: 'x' },
        { a: 'off', b: 'bar', c: 'x' },
        { a: 'on', b: 'baz', c: 'x' },
        { a: 'off', b: 'baz', c: 'x' },
        { a: 'on', b: 'foo', c: 'y' },
        { a: 'off', b: 'foo', c: 'y' },
        { a: 'on', b: 'bar', c: 'y' },
        { a: 'off', b: 'bar', c: 'y' },
        { a: 'on', b: 'baz', c: 'y' },
        { a: 'off', b: 'baz', c: 'y' },
        { a: 'on', b: 'foo', c: 'z' },
        { a: 'off', b: 'foo', c: 'z' },
        { a: 'on', b: 'bar', c: 'z' },
        { a: 'off', b: 'bar', c: 'z' },
        { a: 'on', b: 'baz', c: 'z' },
        { a: 'off', b: 'baz', c: 'z' },
      ]
    end
  end
end
