# == Class: newrelic_installer::install
class newrelic_installer::install (
  $recipe_names          = [],
  $verbosity             = '',
  $environment_variables = {},
  $tags                  = {},
  $proxy                 = '',
  $timeout               = 600,
) {

  # Validate required environment variables
  $nr_api_key = lookup("newrelic::install::new_relic_api_key", undef, undef, '')
  if $nr_api_key == undef or $nr_api_key.length() == 0 {
    fail('New Relic api key not provided')
  }

  $nr_account_id = lookup("newrelic::install::new_relic_account_id", undef, undef, 0)
  if $nr_account_id == undef or $nr_account_id == 0 {
    fail('New Relic account ID not provided')
  }

  $nr_region = lookup("newrelic::install::new_relic_region", undef, undef, '')
  if $nr_region == undef or $nr_region.length() == 0 {
    fail('New Relic region not provided')
  }

  $required_envars = {
    'NEW_RELIC_API_KEY'    => $nr_api_key,
    'NEW_RELIC_ACCOUNT_ID' => $nr_account_id,
    'NEW_RELIC_REGION'     => $nr_region
  }
  # merge hiera-sourced envars with any envar parameters
  $cli_envars = ($required_envars + $environment_variables).map |$index, $value| { "$index=$value" }

  # Validate and transform friendly-recipe names to open-install-library formats
  # TODO create a custom function to handle nice->oil lookups, return in comma-separate list for cli
  if $recipe_names.length() == 0 {
    fail('New Relic <instrumentation? recipe? install?> not provided')
  } else {
    $oil_recipe_names = ["infrastructure-agent-installer"]
  }
  $cli_recipe_arg = "-n ${oil_recipe_names.join(",")}"

  # tranform tags to cli argument
  if !$tags.empty {
    $space_delimited_tags = $tags.map |$index, $value| { "$index:$value" }.join(" ")
    $cli_tag_arg = "--tag nr_deployed_by:puppet-install ${space_delimited_tags} "
  } else {
    $cli_tag_arg = "--tag nr_deployed_by:puppet-install"
  }

  # transform verbosity to cli arugment
  if downcase($verbosity) in ['debug', 'trace'] {
    $cli_verbosity_arg = "--${downcase($verbosity)}"
  } else {
    $cli_verbosity_arg = ""
  }

  case $facts['kernel'] {
    'Linux': {
      remote_file { '/tmp/newrelic_cli_install.sh':
        source => "https://download.newrelic.com/install/newrelic-cli/scripts/install.sh",
        mode   => "777"
      }

      exec { 'install newrelic-cli':
        command   => '/tmp/newrelic_cli_install.sh',
        provider  => shell,
        logoutput => true
      }

      exec { 'install newrelic':
        command     => "/usr/local/bin/newrelic install $cli_recipe_arg -y $cli_tag_arg $cli_verbosity_arg",
        environment => $cli_envars,
        logoutput   => true
      }

      #TODO remove temp file from remote_file
    }
    'windows': {
      remote_file { 'C:\Windows\TEMP\install.ps1':
        source => "https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1",
        mode   => "777"
      }

      exec { 'install newrelic-cli':
        command   => 'powershell -ExecutionPolicy Bypass -File C:\Windows\TEMP\install.ps1',
        provider  => powershell,
        logoutput => true
      }

      exec { 'install newrelic':
        command     => "\"C:\Program Files\New Relic\New Relic CLI\\newrelic.exe\" install  $cli_recipe_arg -y $
          cli_tag_arg $cli_verbosity_arg",
        environment => $cli_envars,
        logoutput   => true
      }

    }
    default: {
      fail("New Relic Install is not yet supported on this platform: ${facts['kernel']}")
    }
  }

  service { "newrelic-infra":
    enable => "true",
    ensure => "running"
  }
}
