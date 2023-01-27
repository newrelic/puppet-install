# frozen_string_literal: true

require 'spec_helper'

describe 'newrelic_installer::install' do
  on_supported_os.each do |os, os_facts|
    context "installed and running newrelic-infra on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['some-valid-recipe-name'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'some-region'
          },
          'verbosity' => 'loud',
          'proxy' => 'some-valid-url'
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_service('newrelic-infra').only_with('ensure' => 'running', 'enable' => true) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing api key on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['some-valid-recipe-name'],
          'environment_variables' => {
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'some-region'
          },
          'verbosity' => 'loud',
          'proxy' => 'some-valid-url'
        }
      end

      it { is_expected.to compile.and_raise_error(%r{New Relic api key not provided}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing account id on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['some-valid-recipe-name'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_REGION' => 'some-region'
          },
          'verbosity' => 'loud',
          'proxy' => 'some-valid-url'
        }
      end

      it { is_expected.to compile.and_raise_error(%r{New Relic account ID not provided}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "failing with missing region on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['some-valid-recipe-name'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
          },
          'verbosity' => 'loud',
          'proxy' => 'some-valid-url'
        }
      end

      it { is_expected.to compile.and_raise_error(%r{New Relic region not provided}) }
    end
  end
end
