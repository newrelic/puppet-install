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
# [*creates*]
#   Path that exists once the targets are installed, e.g. the infrastructure agent binary
#   ('/usr/bin/newrelic-infra', 'C:\Program Files\New Relic\newrelic-infra\newrelic-infra.exe').
#   While it exists, neither the New Relic CLI nor the instrumentation is installed again:
#   without it, every Puppet run reinstalls the latest version of the targets and restarts them.
#   Defaults to undef (installation run on every Puppet run).
#   Cannot be used with agent_version.
# [*agent_version*]
#   Version of the infrastructure agent to install, e.g. '2.0.1' (requires the 'infrastructure' target).
#   The installation runs only when the installed agent does not report this exact version
#   (`newrelic-infra -version`): an agent already at this version is neither reinstalled nor
#   restarted. To upgrade, change the version. The CLI then installs this exact version
#   (INFRASTRUCTURE_AGENT_INSTALLER_VERSION) instead of the latest one.
#   Defaults to undef (installation run on every Puppet run, unless creates is set).
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
  Optional[String[1]] $creates     = undef,
  Optional[Pattern[/\A[0-9]+\.[0-9]+\.[0-9]+\z/]] $agent_version = undef,
) {
  if $agent_version and $creates {
    fail('newrelic_installer: set either agent_version or creates, not both')
  }
  if $agent_version and !('infrastructure' in $targets) {
    fail("newrelic_installer: agent_version requires the 'infrastructure' target")
  }

  # Validate and transform friendly-recipe names to open-install-library formats
  $recipes = newrelic_installer::targets_to_recipes($targets)
  if $recipes.length() == 0 {
    fail('Valid New Relic instrumentation target not provided')
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
  or !(upcase($environment_variables['NEW_RELIC_REGION']) in ['US', 'EU', 'JP', 'STAGING']) {
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

  # prevent bundling of infra and logs
  $skip_core = { 'NEW_RELIC_CLI_SKIP_CORE' => 1 }

  # pinned agent version, read by the infrastructure agent recipes of the CLI
  if $agent_version {
    $version_envar = { 'INFRASTRUCTURE_AGENT_INSTALLER_VERSION' => $agent_version }
  } else {
    $version_envar = {}
  }

  # transform environment_variables to cli argument (really an array of key=value)
  $cli_envars = ($environment_variables + $proxy_envar + $nr_region + $skip_core + $version_envar).map |$key, $value| { "${key}=${value}"
  }

  # Succeeds when the installed agent reports the wanted version (fails when it is not installed).
  # The trailing comma of "version: X.Y.Z," keeps 2.0.1 from matching 2.0.10.
  if $agent_version {
    # Starts with /usr/bin/test: exec fails, instead of installing, when the first command of a check does not exist
    $linux_unless = "/usr/bin/test -x /usr/bin/newrelic-infra && /usr/bin/newrelic-infra -version | /bin/grep -qF 'version: ${agent_version},'"
    # Test-Path first: calling a missing exe raises an error and the exit code would depend on the host.
    # Single quotes only: the check is also passed in double quotes to powershell.exe -Command
    $windows_check = "\$e = 'C:\\Program Files\\New Relic\\newrelic-infra\\newrelic-infra.exe'; if ((Test-Path \$e) -and ((& \$e -version) | Out-String).Contains('version: ${agent_version},')) { exit 0 }; exit 1" # lint:ignore:140chars
    $windows_unless_cmd = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoProfile -NonInteractive -Command \"${windows_check}\""
  } else {
    $linux_unless = undef
    $windows_check = undef
    $windows_unless_cmd = undef
  }

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
        mode   => '511',
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli':
        command     => strip('/tmp/newrelic_cli_install.sh'),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        creates     => $creates,
        unless      => $linux_unless,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation':
        command     => strip("/usr/local/bin/newrelic install ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}")
        ,
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        creates     => $creates,
        unless      => $linux_unless,
        logoutput   => true,
      }
    }
    'windows': {
      remote_file { 'C:\Windows\TEMP\install.ps1':
        ensure => present,
        source => 'https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1',
        mode   => '511',
        proxy  => $proxy,
      }
      -> exec { 'install newrelic-cli':
        command     => strip('powershell -ExecutionPolicy Bypass -File C:\Windows\TEMP\install.ps1'),
        provider    => powershell,
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        creates     => $creates,
        unless      => $windows_check,
        logoutput   => true,
      }
      -> exec { 'install newrelic instrumentation':
        command     => strip("\"C:\\Program Files\\New Relic\\New Relic CLI\\newrelic.exe\" install ${cli_recipe_arg} -y ${cli_tag_arg} ${cli_verbosity_arg}"),
        environment => $cli_envars,
        timeout     => $install_timeout_seconds,
        creates     => $creates,
        unless      => $windows_unless_cmd,
        logoutput   => true,
      }
    }
    default: {
      fail("New Relic Install is not yet supported on this platform: ${facts['kernel']}")
    }
  }
}
