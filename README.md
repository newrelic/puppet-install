<a href="https://opensource.newrelic.com/oss-category/#community-project"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Project.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Project.png"><img alt="New Relic Open Source community project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Project.png"></picture></a>

# New Relic Puppet module

`newrelic-newrelic_installer` is a [Puppet module](https://forge.puppet.com/modules/newrelic/newrelic_installer/readme) that will help you scale your New Relic Observability efforts. It uses the [New Relic CLI](https://github.com/newrelic/newrelic-cli) and [New Relic Open Installation repository](https://github.com/newrelic/open-install-library) to achieve this.

Currently, we have included Linux and Windows support for New Relic's Infrastructure and Logs integrations, with more agents and integrations following in the near future.

**Note: Installing specific versions of an agent is not supported, this role will always install latest released version of a New Relic agent.**

## Installation

### Puppet Forge

```shell
puppet module install newrelic-newrelic_installer
```

View more installation options on [PuppetForge](https://forge.puppet.com/modules/newrelic/newrelic_installer/readme) 


### Manual

* Install puppet development kit: https://www.puppet.com/docs/pdk/2.x/pdk_install.html 
* Clone repo and build a tarball of the module using `pdk build`
  * e.g. `pkg/newrelic-newrelic_installer-0.1.0.tar.gz` 
* Copy module tarball to your master node and install manually
```shell
sudo puppet module install ~/newrelic-newrelic_installer-0.1.0.tar.gz
Notice: Preparing to install into /etc/puppetlabs/code/environments/production/modules ...
Notice: Downloading from https://forgeapi.puppet.com ...
Notice: Installing -- do not interrupt ...
/etc/puppetlabs/code/environments/production/modules
└─┬ newrelic-newrelic_installer (v0.1.0)
  ├── lwf-remote_file (v1.1.3)
  └── puppetlabs-powershell (v5.2.0)
```
## Getting Started 
To use this module, you'll need to instantiate the `::install` class, specifying an instrumentation target and some New Relic account-specific details.  For example:
```ruby
# /etc/puppetlabs/code/environments/<YOUR_ENVIRONMENT>/manifests/site.pp
class { 'newrelic_installer::install':
          targets               => ["infrastructure", "logs", "php", "dotnet"],
          environment_variables => {
            "NEW_RELIC_API_KEY"          => "<YOUR-NR-API-KEY>",
            "NEW_RELIC_ACCOUNT_ID"       => <YOUR-NR-ACCOUNT-ID>,
            "NEW_RELIC_REGION"           => "<US|EU>",
            "NEW_RELIC_APPLICATION_NAME" => "<YOUR-PHP-APPLICATION-NAME>"
          }
}
```
### Parameters
#### `targets` _[String]_          
Specifies target to be instrumented with New Relic 
Supported values include:
* `'infrastructure'` - New Relic Infrastructure Agent
* `'logs'` - Logs integration for New Relic Infrastructure Agent. **requires `'infrastructure'`*
* `'php'` - New Relic PHP APM Agent
* `'dotnet'` - New Relic .Net APM Agent
* `'nodejs'` - New Relic Node APM Agent
#### `environment_variables` _Hash_ 
Hash of environment variables to set prior to execution.
* `NEW_RELIC_API_KEY`: your New Relic API key **required*
* `NEW_RELIC_ACCOUNT_ID`: your New Relic account id **required*
* `NEW_RELIC_REGION`: your New Relic account's region (`US` or `EU`).  Defaults to `US` if not specified
* `NEW_RELIC_APPLICATION_NAME`: used by `'php'`. This config option sets the application name that data is reported under in APM. Defaults to `'PHP Application'` if not specified.
#### `verbosity` _String_ (optional)
Specifies command output verbosity
Supported values include
* `debug`
* `trace`
#### `tags` _Hash_ (optional)
Hash of tags associated with entities instrumented with New Relic.  Examples:
* `{'key-name' => 'value', 'foo' => 'bar'}`
#### `proxy` _String_ (optional)
Sets the proxy server the agent should use. Examples:
* `https://myproxy.foo.com:8080`
* `http://10.10.254.254`
#### `install_timeout_seconds` _Integer_ (optional)
Sets the timeout in seconds for New Relic installations.  Default is 600

## Support
New Relic hosts and moderates an online forum where customers can interact with
New Relic employees as well as other customers to get help and share best
practices. Like all official New Relic open source projects, there's a related
Community topic in the New Relic Explorers Hub. You can find this project's
topic/threads here:

* [New Relic Documentation](https://docs.newrelic.com): Comprehensive guidance for using our platform
* [New Relic Community](https://forum.newrelic.com): The best place to engage in troubleshooting questions
* [New Relic Developer](https://developer.newrelic.com/): Resources for building a custom observability applications
* [New Relic University](https://learn.newrelic.com/): A range of online training for New Relic users of every level
* [New Relic Technical Support](https://support.newrelic.com/) 24/7/365 ticketed support. Read more about our [Technical Support Offerings](https://docs.newrelic.com/docs/licenses/license-information/general-usage-licenses/support-plan).

## Contribute

We encourage your contributions to improve the `newrelic_installer` Puppet module! Keep in mind that when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.


If you have any questions, or to execute our corporate CLA (which is required if your contribution is on behalf of a company), drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

## License
This project is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
