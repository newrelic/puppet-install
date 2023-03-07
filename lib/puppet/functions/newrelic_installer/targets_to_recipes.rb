# frozen_string_literal: true

# https://github.com/puppetlabs/puppet-specifications/blob/master/language/func-api.md#the-4x-api
Puppet::Functions.create_function(:"newrelic_installer::targets_to_recipes") do
  dispatch :targets_to_recipes do
    param 'Tuple', :a
    return_type 'String' # list of comma-separated recipes
  end
  def targets_to_recipes(targets)
    recipes = []
    valid_recipe_mappings = { 'infrastructure' => 'infrastructure-agent-installer' }

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
