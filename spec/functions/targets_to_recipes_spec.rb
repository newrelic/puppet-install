# frozen_string_literal: true

require 'spec_helper'

describe 'newrelic_installer::targets_to_recipes' do
  # single valid recipe
  it { is_expected.to run.with_params(['infrastructure']).and_return('infrastructure-agent-installer') }
  # valid and invalid
  it { is_expected.to run.with_params(['infrastructure', 'nope']).and_return('infrastructure-agent-installer') }
  # all invalid
  it { is_expected.to run.with_params(['nope']).and_return('') }
end
