![Validate Workflows](https://github.com/plzm/azure-deploy/actions/workflows/validate-workflows.yml/badge.svg)  

![Create Powershell Modules ](https://github.com/plzm/azure-deploy/actions/workflows/create-modules.yml/badge.svg)  

## Azure deployment artifacts: ARM templates, scripts, etc.

/scripts/ contains mostly Powershell but also some Bash scripts. Some are mostly scratch format, whereas others - particularly in the /scripts/ directory - can be dot-sourced and are higher quality.

/modules/ contains Powershell .psm/.psd1 modules. Currently plzm.Azure is built automatically from all the .ps1 files in /scripts/.

/template/ contains many ARM templates I have put together. The intent is:
- To provide templates which are each responsible for exactly one Azure resource type - no giant spaghetti templates mingling resources, which are only ever useful once, instead these are templates which can be assembled flexibly in... scripts, infrastructure deployment pipelines, etc.
- To heavily parameterize templates so they are very flexible for different scenarios
- To include lots of conditional logic (ARM functions etc.) to make templates still more flexible for different scenarios
I have used these ARM templates on several production projects so they have been thoroughly tested and have successfully deployed many Azure resources.

---

### PLEASE NOTE FOR THE ENTIRETY OF THIS REPOSITORY AND ALL ASSETS
#### 1. No warranties or guarantees are made or implied.
#### 2. All assets here are provided by me "as is". Use at your own risk. Validate before use.
#### 3. I am not representing my employer with these assets, and my employer assumes no liability whatsoever, and will not provide support, for any use of these assets.
#### 4. Use of the assets in this repo in your Azure environment may or will incur Azure usage and charges. You are completely responsible for monitoring and managing your Azure usage.

---

Unless otherwise noted, all assets here are authored by me. Feel free to examine, learn from, comment, and re-use (subject to the above) as needed and without intellectual property restrictions.

If anything here helps you, attribution and/or a quick note is much appreciated.
