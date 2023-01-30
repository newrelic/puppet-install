# frozen_string_literal: true

require 'spec_helper'

describe 'newrelic_installer::install' do
  on_supported_os.each do |os, os_facts|
    # filters only Linux kernel, reads a bit odd
    # next unless os_facts[:kernel] == 'Linux'
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
          'verbosity' => '',
          'proxy' => ''
        }
      end

      # kernel-specific asserts
      if os_facts[:kernel] == 'Linux'
        it { is_expected.to contain_remote_file('/tmp/newrelic_cli_install.sh').with('source' => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.sh', 'ensure' => 'present', 'mode' => '777') }
        it { is_expected.to contain_remote_file('/tmp/newrelic_cli_install.sh').that_comes_before('Exec[install newrelic-cli]') }
      elsif os_facts[:kernel] == 'windows'
        it { is_expected.to contain_remote_file('C:\Windows\TEMP\install.ps1').with('source' => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1', 'ensure' => 'present', 'mode' => '777') }
        it { is_expected.to contain_remote_file('C:\Windows\TEMP\install.ps1').that_comes_before('Exec[install newrelic-cli]') }
      end
      # common asserts
      it { is_expected.to contain_exec('install newrelic-cli').that_comes_before('Exec[install newrelic instrumentation]') }
      it { is_expected.to have_exec_resource_count(2) }
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
          'verbosity' => '',
          'proxy' => ''
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
          'verbosity' => '',
          'proxy' => ''
        }
      end
      it { is_expected.to compile.and_raise_error(%r{New Relic region not provided}) }
    end
  end
end
