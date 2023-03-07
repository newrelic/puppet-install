# == Class: newrelic_installer::install
# === Required Parameters
# [*targets*]
#   Targets that you are attempting to instrument with New Relic
#
# [*environment_variables*]
#   Hash of environment variables that are used when running New Relic.
#   Required keys
#   - NEW_RELIC_API_KEY
#   - NEW_RELIC_ACCOUNT_ID
#   - NEW_RELIC_REGION - defaults to 'US' if not specified
#
# === Optional Parameters
# [*verbosity*]
#   Verbosity of New Relic install command (debug, trace)
# [*tags*]
#   Hash of tags to pass to New Relic install command
# [*proxy*]
#   Valid URL, including protocol and port, for proxy
# [*install_timeout_seconds*]
#   Timeout for exec commands, defaults to 600 seconds
#
# === Authors
#
# New Relic, Inc.
#
class newrelic_installer::install (
  Array $targets                   = [],
  Hash $environment_variables      = {},
  String $verbosity                = '', # lint:ignore:params_empty_string_assignment
  Hash $tags                       = {},
  String $proxy                    = '', # lint:ignore:params_empty_string_assignment
  Integer $install_timeout_seconds = 600,
) {
  # Validate and transform friendly-recipe names to open-install-library formats
  $recipes = newrelic_installer::targets_to_recipes($targets)
  if $recipes.length() == 0 {
    fail('New Relic instrumentation target not provided')
  }
  $cli_recipe_arg = "-n ${recipes}"

  # Validate required environment variables
  $nr_api_key = $environment_variables['NEW_RELIC_API_KEY']
  if $nr_api_key == undef or $nr_api_key.length() == 0 {
    fail('New Relic api key not provided')
  }
  $nr_account_id = $environment_variables['NEW_RELIC_ACCOUNT_ID']
  if $nr_account_id == undef or $nr_account_id == 0 {
    fail('New Relic account ID not provided')
  }
  # Default region to US
  if $environment_variables['NEW_RELIC_REGION'] == undef
  or $environment_variables['NEW_RELIC_REGION'].length() == 0
  or !(upcase($environment_variables['NEW_RELIC_REGION']) in ['US', 'EU', 'STAGING']) {
    $nr_region = { 'NEW_RELIC_REGION' => 'US' }
  } else {
    $nr_region = { 'NEW_RELIC_REGION' => "${upcase($environment_variables['NEW_RELIC_REGION'])}" }
  }

  # transform proxy to envar
  if $proxy == undef or $proxy.length() == 0 {
    $proxy_envar = {}
  } else {
    $proxy_envar = {
      'HTTPS_PROXY' => $proxy,
    }
  }
  # transform environment_variables to cli argument (really an array of key=value)
  $cli_envars = ($environment_variables + $proxy_envar + $nr_region).map |$key, $value| { "${key}=${value}" }

  # transform verbosity to cli argument
  if $verbosity != undef and downcase($verbosity) in ['debug', 'trace'] {
    $cli_verbosity_arg = "--${downcase($verbosity)}"
  } else {
    $cli_verbosity_arg = undef
  }

  # tranform tags to cli argument
  if !$tags.empty {
    $space_delimited_tags = $tags.map |$index, $value| { "${index}:${value}" }.join(',')
    $cli_tag_arg = "--tag nr_deployed_by:puppet-install,${space_delimited_tags} "
  } else {
    $cli_tag_arg = '--tag nr_deployed_by:puppet-install'
  }

  case $facts['kernel'] {
    'Linux': {
      remote_file { '/tmp/newrelic_cli_install.sh':
        ensure => present,
        source => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.sh',
        mode   => '777',
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli':
        command     => strip('/tmp/newrelic_cli_install.sh'),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation':
        command     => strip("/usr/local/bin/newrelic install ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}")
        ,
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> service { 'newrelic-infra':
        ensure => 'running',
        enable => 'true',
      }
    }
    'windows': {
      remote_file { 'C:\Windows\TEMP\install.ps1':
        ensure => present,
        source => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1',
        mode   => '777',
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli':
        command     => strip('powershell -ExecutionPolicy Bypass -File C:\Windows\TEMP\install.ps1'),
        provider    => powershell,
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation':
        command     => strip("\"C:\\Program Files\\New Relic\\New Relic CLI\\newrelic.exe\" install ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}"),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> service { 'newrelic-infra':
        ensure => 'running',
        enable => 'true',
      }
    }
    default: {
      fail("New Relic Install is not yet supported on this platform: ${facts['kernel']}")
    }
  }
}
