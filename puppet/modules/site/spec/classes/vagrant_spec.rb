# frozen_string_literal: true

require 'spec_helper'

describe 'site::vagrant' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { massage_os_facts(os_facts) }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_pam__access__rule('vagrant_simp').with_users(['vagrant', 'simp']) }
      it { is_expected.to create_sudo__user_specification('simp_sudo').with_user_list(['simp']) }
      it { is_expected.to create_sudo__default_entry('simp_default_notty').with_content(['!env_reset, !requiretty']) }
      it { is_expected.to create_sudo__default_entry('vagrant_default_notty').with_content(['!env_reset, !requiretty']) }
    end
  end
end
