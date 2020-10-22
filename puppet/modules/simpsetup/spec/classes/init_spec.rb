# frozen_string_literal: true

require 'spec_helper'

describe 'simpsetup' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { massage_os_facts(os_facts) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('simpsetup') }
    end
  end
end
