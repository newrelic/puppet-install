# frozen_string_literal: true

require 'spec_helper'

def required_vars
  {
    'environment_variables' => {
      'NEW_RELIC_API_KEY' => 'some-api-key',
      'NEW_RELIC_ACCOUNT_ID' => 123,
    },
  }
end

describe 'newrelic_installer::install' do
  targets = ['infrastructure', 'php', 'dotnet', 'nodejs']
  on_supported_os.each do |os, os_facts|
    targets.each do |target|
      context "installed target=#{target} and running newrelic-infra on #{os}" do
        let(:facts) { os_facts }
        let(:params) do
          required_vars.merge({ 'targets' => [target] })
        end

        # kernel-specific asserts
        if os_facts[:kernel] == 'Linux'
          it { is_expected.to contain_remote_file('/tmp/newrelic_cli_install.sh').with('source' => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.sh', 'ensure' => 'present', 'mode' => '511').that_comes_before('Exec[install newrelic-cli]') }
          it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)newrelic install(.*)--tag nr_deployed_by:puppet-install}) }
        elsif os_facts[:kernel] == 'windows'
          it { is_expected.to contain_remote_file('C:\Windows\TEMP\install.ps1').with('source' => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1', 'ensure' => 'present', 'mode' => '511').that_comes_before('Exec[install newrelic-cli]') }
          it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)newrelic.exe" install(.*)--tag nr_deployed_by:puppet-install}) }
        end

        # common asserts
        it { is_expected.to have_exec_resource_count(2) }
        it { is_expected.to contain_exec('install newrelic instrumentation').with('environment' => %r{(.*)NEW_RELIC_REGION=US(.*)NEW_RELIC_CLI_SKIP_CORE=1(.*)}) }
        it { is_expected.to contain_exec('install newrelic-cli').that_comes_before('Exec[install newrelic instrumentation]') }
      end
    end
  end

  on_supported_os.each do |os, os_facts|
    context "failing with missing api key on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'some-region'
          },
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
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_REGION' => 'some-region'
          },
        }
      end

      it { is_expected.to compile.and_raise_error(%r{New Relic account ID not provided}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "default to US when invalid region on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'kaboom'
          },
        }
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('environment' => %r{(.*)NEW_RELIC_REGION=US(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installs using EU as region #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'eu'
          },
        }
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('environment' => %r{(.*)NEW_RELIC_REGION=EU(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installs explicity pass US as region #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'us'
          },
        }
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('environment' => %r{(.*)NEW_RELIC_REGION=US(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installed with debug verbosity on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'verbosity' => 'debug', 'proxy' => '' })
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)--debug(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installed with trace verbosity on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'verbosity' => 'trace', 'proxy' => '' })
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)--trace(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installed with optional tags on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge('targets' => ['infrastructure'], 'tags' => { 'some-tag' => 'some-value', 'another-tag' => 'another-value' })
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)--tag nr_deployed_by:puppet-install,some-tag:some-value,another-tag:another-value(.*)}) }
    end
  end
  on_supported_os.each do |os, os_facts|
    context "installed with trace verbosity on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['agent-control'], 'verbosity' => 'trace', 'proxy' => '' })
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('command' => %r{(.*)--trace(.*)}) }
    end
  end
end
