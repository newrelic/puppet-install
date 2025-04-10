# Developer Guide: Local testing of `newrelic-newrelic_installer` puppet module

This guide provides step-by-step instructions for installing the Puppet agent on a standalone instance, installing the `newrelic-newrelic_installer` module, configuring it to install the New Relic Agent, making changes to the module, testing those changes locally, and creating a release.

> **Note:** The below commands are outlined for an Ubuntu system. Please adjust the commands according to your operating system.

---

## 1. Install Puppet Agent on a Standalone System

The Puppet agent is required to manage configurations on a standalone system. Follow these steps to install it:

### Install puppet agent
```bash
curl -O https://apt.puppet.com/puppet7-release-focal.deb
sudo dpkg -i puppet7-release-focal.deb
sudo apt update
sudo apt install -y puppet-agent
```


### Verify Installation

Ensure the Puppet agent is installed and running correctly.
```bash
/opt/puppetlabs/bin/puppet --version
```

---

## 2. Install the New Relic Installer Module

The `newrelic-newrelic_installer` module allows you to installs and configures New Relic instrumentation using Puppet.

### Install the Module from puppet forge
```bash
sudo /opt/puppetlabs/bin/puppet module install newrelic-newrelic_installer
```

> **Note:** The default location where Puppet modules are installed is `/etc/puppetlabs/code/environments/production/modules/`. If the above command displays a different location for the `newrelic-newrelic_installer` module, then use the path in the `--modulePath` option in the subsequent commands mentioned in this document.

### Verify Installation
Run the following command to list all installed Puppet modules and verify that the `newrelic-newrelic_installer` module is present:

```bash
sudo /opt/puppetlabs/bin/puppet module list --modulepath=/etc/puppetlabs/code/environments/production/modules
```

This command will display a list of installed modules, including their versions. Ensure that `newrelic-newrelic_installer` is listed.



---

## 3. Create and Apply a Manifest File

### Create the Manifest File
```bash
sudo vi "/etc/puppetlabs/code/environments/production/manifests/site.pp"
```
Open the file and paste the code snippet provided by the [New Relic Puppet Data Source](https://one.newrelic.com/marketplace/install-data-source?state=8fe4addd-61b9-5878-e445-3c5cd3b1ec5b).For example:


```puppet
class { 'newrelic_installer::install':
    targets              => ['infrastructure'],
    environment_variables => {
        'NEW_RELIC_API_KEY'    => '<YOUR-NR-API-KEY>',
        'NEW_RELIC_ACCOUNT_ID' => <YOUR-NR-ACCOUNT-ID>,
        'NEW_RELIC_REGION'     => 'US', # or 'EU' based on your account
    },
}
```
Replace `<YOUR-NR-API-KEY>` and `<YOUR-NR-ACCOUNT-ID>` with your New Relic API key and account ID, respectively.

### Apply the Manifest
```bash
sudo /opt/puppetlabs/bin/puppet apply --modulepath=/etc/puppetlabs/code/environments/production/modules /etc/puppetlabs/code/environments/production/manifests/site.pp
```
This command will install the target specified in the site.pp file



---

## 4. Make any changes in the `newrelic-newrelic_installer` module

You can directly modify the installed `newrelic-newrelic_installer` module to customize its behavior.

### Navigate to the installed module
```bash
cd /etc/puppetlabs/code/environments/production/modules/newrelic_installer
```

### Edit the Module
```bash
sudo vi manifests/install.pp
```



### Save Changes
Save the file

---

## 5. Test the Changes Locally

After making changes to the installed module, you can directly test them by applying the manifest.

### Run the Updated Module
```bash
sudo /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp --modulepath=/etc/puppetlabs/code/environments/production/modules
```
> **Note:** Use the `--debug` flag with the `puppet apply` command to get detailed debug logs.


---

## 6. Create a Release

The release process is automated using the  workflow files. When you push a Git tag, the workflow will handle the release process, including packaging and publishing the module to Puppet Forge.

### Update the Version
Update the module's version in the `metadata.json` file.
```json
{
    "name": "newrelic-newrelic_installer",
    "version": "0.5.4",
    "author": "Your Name",
    "summary": "New Relic Infrastructure Installer Module",
    "license": "Apache-2.0"
}
```

### Commit the Changes
Commit your changes to the repository.

### Push a Git Tag
Push a new Git tag to trigger the release workflow. Refer to [this](https://git-scm.com/book/en/v2/Git-Basics-Tagging) for information on creating and pushing a tag.

This will package the module, publish it to Puppet Forge, and complete the release process.

---
