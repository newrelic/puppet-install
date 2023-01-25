[![New Relic Experimental header](https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Experimental.png)](https://opensource.newrelic.com/oss-category/#new-relic-experimental)
# New Relic installation using Puppet
This Puppet module installs and configures New Relic instrumentation on user-specified targets 

## Installation
### Puppet Forge
**Coming soon**: `puppet module install newrelic-newrelic_installer --version 0.1.0`

### Manual
* Install puppet development kit: https://www.puppet.com/docs/pdk/2.x/pdk_install.html 
* Clone repo and execute `pdk build`.  This will build the module to `pkg/newrelic-install-0.1.0.tar.gz`
* Copy `pkg/newrelic-install-0.1.0.tar.gz` to your master node and install manually
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

* instantiate the agent via sites.pp
```ruby
node "your-managed-node.example.com" {
  class { 'newrelic_installer::install':
    targets => ["infrastructure"]
  }
}
```

* run `puppet agent -tv` on `your-managed-node.example.com`

## Getting Started 
Once this module is installed, you will need to update the following keys in `common.yml`
```shell
/etc/puppetlabs/code/environments/<YOUR_ENVIRONMENT>/modules/newrelic_installer/data$ cat common.yaml 
---
newrelic_installer::install::new_relic_api_key: <YOUR-API-KEY>
newrelic_installer::install::new_relic_account_id: <YOUR-ACCOUNT-ID>
newrelic_installer::install::new_relic_region: <YOUR-REGION>
```

Then declare an instance of the `::install` class for your hosts.  For example:
```ruby
# /etc/puppetlabs/code/environments/<YOUR_ENVIRONMENT>/manifests/sites.pp
  class { 'newrelic_installer::install':
    targets => ["infrastructure"]
  }
```

## Variables
### Hiera keys
#### `newrelic_installer::install::new_relic_api_key` 
Your New Relic API Key
#### `newrelic_installer::install::new_relic_account_id` 
Your New Relic Account ID
#### `newrelic_installer::install::new_relic_region` 
New Relic Region
Supported values include:
* `US`
* `EU`


### Parameters
#### `targets` _[String]_          
Specifies target to be instrumented with New Relic 
Supported values include:
* `'infrastructure'` - New Relic Infrastructure Agent

#### `verbosity` _String_ (optional)
Specifies command output verbosity
Supported values include
* `debug`
* `trace`
#### `environment_variables` _Hash_ (optional)
Hash of environment variables to set prior to execution.  Examples:
* `{'SOME_ENVAR' => "some-value", 'ANOTHER_ENVAR' => 123}`
#### `tags` _Hash_ (optional)
Hash of tags associated with entities instrumented with New Relic.  Examples:
* `{'environment' => 'production', 'version' => '1.2.3'}`
#### `proxy` _String_ (optional)
Sets the proxy server the agent should use. Examples:
* `https://myproxy.foo.com:8080`
* `http://10.10.254.254`
#### `timeout` _Integer_ (optional)

## Support
New Relic hosts and moderates an online forum where customers can interact with
New Relic employees as well as other customers to get help and share best
practices. Like all official New Relic open source projects, there's a related
Community topic in the New Relic Explorers Hub. You can find this project's
topic/threads here:

* [New Relic Documentation](https://docs.newrelic.com): Comprehensive guidance for using our platform
* [New Relic Community](https://discuss.newrelic.com/c/support-products-agents/new-relic-infrastructure): The best place to engage in troubleshooting questions
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
