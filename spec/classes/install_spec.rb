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
    context "installed on every run without creates on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'] })
      end

      it { is_expected.to contain_exec('install newrelic-cli').without_creates }
      it { is_expected.to contain_exec('install newrelic instrumentation').without_creates }
    end

    context "installed once with creates on #{os}" do
      creates = if os_facts[:kernel] == 'windows'
                  'C:\Program Files\New Relic\newrelic-infra\newrelic-infra.exe'
                else
                  '/usr/bin/newrelic-infra'
                end
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'creates' => creates })
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_exec('install newrelic-cli').with_creates(creates) }
      it { is_expected.to contain_exec('install newrelic instrumentation').with_creates(creates) }
    end

    context "failing with an empty creates on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'creates' => '' })
      end

      it { is_expected.to compile.and_raise_error(%r{parameter 'creates' expects}) }
    end
  end

  on_supported_os.each do |os, os_facts|
    context "installed without agent_version on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'] })
      end

      it { is_expected.to contain_exec('install newrelic-cli').without_unless }
      it { is_expected.to contain_exec('install newrelic instrumentation').without_unless }
      it { is_expected.not_to contain_exec('install newrelic instrumentation').with_environment(%r{INFRASTRUCTURE_AGENT_INSTALLER_VERSION}) }
    end

    context "installed only when the agent is not at agent_version on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'agent_version' => '2.0.1' })
      end

      it { is_expected.to compile.with_all_deps }

      it 'pins the version installed by the CLI' do
        ['install newrelic-cli', 'install newrelic instrumentation'].each do |title|
          is_expected.to contain_exec(title)
            .with_environment(%r{INFRASTRUCTURE_AGENT_INSTALLER_VERSION=2\.0\.1})
            .without_creates
        end
      end

      if os_facts[:kernel] == 'windows'
        check = "$e = 'C:\\Program Files\\New Relic\\newrelic-infra\\newrelic-infra.exe'; if ((Test-Path $e) -and ((& $e -version) | Out-String).Contains('version: 2.0.1,')) { exit 0 }; exit 1"

        it { is_expected.to contain_exec('install newrelic-cli').with_provider('powershell').with_unless(check) }

        it do
          is_expected.to contain_exec('install newrelic instrumentation')
            .with_unless("C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoProfile -NonInteractive -Command \"#{check}\"")
        end
      else
        check = "/usr/bin/test -x /usr/bin/newrelic-infra && /usr/bin/newrelic-infra -version | /bin/grep -qF 'version: 2.0.1,'"

        it { is_expected.to contain_exec('install newrelic-cli').with_unless(check) }
        it { is_expected.to contain_exec('install newrelic instrumentation').with_unless(check) }
      end
    end

    context "failing with agent_version and creates on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'agent_version' => '2.0.1', 'creates' => '/usr/bin/newrelic-infra' })
      end

      it { is_expected.to compile.and_raise_error(%r{set either agent_version or creates, not both}) }
    end

    context "failing with agent_version without the infrastructure target on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['php'], 'agent_version' => '2.0.1' })
      end

      it { is_expected.to compile.and_raise_error(%r{agent_version requires the 'infrastructure' target}) }
    end

    context "failing with an invalid agent_version on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        required_vars.merge({ 'targets' => ['infrastructure'], 'agent_version' => 'latest' })
      end

      it { is_expected.to compile.and_raise_error(%r{parameter 'agent_version' expects}) }
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
    context "installs using JP as region #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'targets' => ['infrastructure'],
          'environment_variables' => {
            'NEW_RELIC_API_KEY' => 'some-api-key',
            'NEW_RELIC_ACCOUNT_ID' => 123,
            'NEW_RELIC_REGION' => 'jp'
          },
        }
      end

      it { is_expected.to contain_exec('install newrelic instrumentation').with('environment' => %r{(.*)NEW_RELIC_REGION=JP(.*)}) }
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
