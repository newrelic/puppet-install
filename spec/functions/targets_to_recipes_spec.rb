# frozen_string_literal: true

require 'spec_helper'

describe 'newrelic_installer::targets_to_recipes' do
  # single valid recipe - infrastructure
  it { is_expected.to run.with_params(['infrastructure']).and_return('infrastructure-agent-installer') }
  it { is_expected.to run.with_params(['php']).and_return('php-agent-installer') }
  it { is_expected.to run.with_params(['dotnet']).and_return('dotnet-agent-installer') }
  # valid and invalid
  it { is_expected.to run.with_params(['infrastructure', 'nope']).and_return('infrastructure-agent-installer') }
  # all invalid
  it { is_expected.to run.with_params(['nope']).and_return('') }
  # infrastructure is missing
  it { is_expected.to run.with_params(['logs']).and_raise_error(Puppet::ParseError) }
  # infrastructure is still missing
  it { is_expected.to run.with_params(['php', 'logs']).and_raise_error(Puppet::ParseError) }
  it { is_expected.to run.with_params(['dotnet', 'logs']).and_raise_error(Puppet::ParseError) }
end
