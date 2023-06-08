# frozen_string_literal: true

require 'set'

# https://github.com/puppetlabs/puppet-specifications/blob/master/language/func-api.md#the-4x-api
Puppet::Functions.create_function(:"newrelic_installer::targets_to_recipes") do
  dispatch :targets_to_recipes do
    param 'Tuple', :a
    return_type 'String' # list of comma-separated recipes
  end
  def targets_to_recipes(targets)
    if targets.empty?
      raise Puppet::ParseError, 'You must specify at least one instrumentation target.'
    end

    valid_recipe_mappings = {
      'infrastructure' => 'infrastructure-agent-installer',
      'logs' => 'logs-integration',
      'php' => 'php-agent-installer',
      'nodejs' => 'node-agent-installer'
    }
    requires_infrastructure_set = Set['logs']

    targets_set = Set.new(targets)
    targets_dependent_on_infrastructure_set = targets_set & requires_infrastructure_set

    if !targets_dependent_on_infrastructure_set.empty? && !targets_set.include?('infrastructure')
      message = "Infrastructure is required for the following: #{targets_dependent_on_infrastructure_set.to_a}. Add 'infrastructure' to your targets."
      raise Puppet::ParseError, message
    end

    recipes = []

    targets.each do |target|
      if valid_recipe_mappings.key?(target)
        recipes << valid_recipe_mappings[target]
      else
        Warning.warn("Warning: Valid recipe not found for target '#{target}', skipping\n")
      end
    end

    recipes.join(',')
  end
end
