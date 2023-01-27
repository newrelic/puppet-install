# == Class: newrelic_installer::install
class newrelic_installer::install (
  $targets                 = [],
  $environment_variables   = {},
  $verbosity               = '',
  $tags                    = {},
  $proxy                   = undef,
  $install_timeout_seconds = 600,
) {
  # Validate and transform friendly-recipe names to open-install-library formats
  # TODO create a custom function to handle nice->oil lookups, return in comma-separate list for cli
  if $targets.length() == 0 {
    fail('New Relic <instrumentation? recipe? install?> not provided')
  } else {
    $oil_recipe_names = ["infrastructure-agent-installer"]
  }
  $cli_recipe_arg = "-n ${oil_recipe_names.join(",")}"

  # Validate required environment variables
  $nr_api_key = $environment_variables['NEW_RELIC_API_KEY']
  if $nr_api_key == undef or $nr_api_key.length() == 0 {
    fail('New Relic api key not provided')
  }
  $nr_account_id = $environment_variables['NEW_RELIC_ACCOUNT_ID']
  if $nr_account_id == undef or $nr_account_id == 0 {
    fail('New Relic account ID not provided')
  }
  $nr_region = $environment_variables['NEW_RELIC_REGION']
  if $nr_region == undef or $nr_region.length() == 0 {
    fail('New Relic region not provided')
  }
  # transform proxy to envar
  if $proxy == undef or $proxy.length() == 0 {
    $proxy_envar = {}
  } else {
    $proxy_envar = {
      'HTTPS_PROXY' => $proxy
    }
  }
  # transform environment_variables to cli argument (really an array of key=value)
  $cli_envars = ($environment_variables + $proxy_envar).map |$key, $value| { "${key}=${value}" }

  # transform verbosity to cli argument
  if downcase($verbosity) in ['debug', 'trace'] {
    $cli_verbosity_arg = "--${downcase($verbosity)}"
  } else {
    $cli_verbosity_arg = undef
  }

  # tranform tags to cli argument
  if !$tags.empty {
    $space_delimited_tags = $tags.map |$index, $value| { "${index}:${value}" }.join(" ")
    $cli_tag_arg = "--tag nr_deployed_by:puppet-install ${space_delimited_tags} "
  } else {
    $cli_tag_arg = "--tag nr_deployed_by:puppet-install"
  }

  case $facts['kernel'] {
    'Linux': {
      remote_file { '/tmp/newrelic_cli_install.sh' :
        ensure => present,
        source => "https://download.newrelic.com/install/newrelic-cli/scripts/install.sh",
        mode   => "777",
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli' :
        command     => strip('/tmp/newrelic_cli_install.sh'),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation' :
        command     => strip("/usr/local/bin/newrelic install ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}"),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> service { "newrelic-infra" :
        ensure => "running",
        enable => "true",
      }
    }
    'windows': {
      remote_file { 'C:\Windows\TEMP\install.ps1' :
        ensure => present,
        source => "https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1",
        mode   => "777",
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli' :
        command     => strip('powershell -ExecutionPolicy Bypass -File C:\Windows\TEMP\install.ps1'),
        provider    => powershell,
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation' :
        command     => strip("\"C:\Program Files\New Relic\New Relic CLI\\newrelic.exe\" install  ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}"),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        logoutput   => true,
      }
      -> service { "newrelic-infra" :
        ensure => "running",
        enable => "true",
      }
    }
    default: {
      fail("New Relic Install is not yet supported on this platform: ${facts['kernel']}")
    }
  }


}
