# frozen_string_literal: true

require 'spec_helper'

describe 'newrelic::install' do
  on_supported_os.each do |os, os_facts|
    context "installed and running newrelic-infra on #{os}" do
      let(:facts) { os_facts }
      let('mock the hiera') {
        MockFunction.new('hiera') { |f|
          f.stubbed.with('non-ex').raises(Puppet::ParseError.new('Key not found'))
          f.stubbed.with('db-password').returns('password1')
        }
      }
      let(:params) {
        {
          'new_relic_api_key' => 'some-api-key',
          'new_relic_account_id' => 1234567890,
          'region' => 'some-valid-region',
          'recipe_names' => ['some-valid-recipe-name']
        }
      }
      it { is_expected.to compile }
      it { is_expected.to contain_service('newrelic-infra').only_with('ensure' => 'running', 'enable' => true) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing api key on #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          'new_relic_account_id' => 1234567890,
          'region' => 'some-valid-region',
          'recipe_names' => ['some-valid-recipe-name']
        }
      }
      it { is_expected.to compile.and_raise_error(/New Relic api key not provided/) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing account id on #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          'new_relic_api_key' => 'some-api-key',
          'region' => 'some-valid-region',
          'recipe_names' => ['some-valid-recipe-name']
        }
      }
      it { is_expected.to compile.and_raise_error(/New Relic account ID not provided/) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing region on #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          'new_relic_api_key' => 'some-api-key',
          'new_relic_account_id' => 123456789,
          'recipe_names' => ['some-valid-recipe-name']
        }
      }
      it { is_expected.to compile.and_raise_error(/New Relic region not provided/) }
    end
  end
end
