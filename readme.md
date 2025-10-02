![Validate Workflows](https://github.com/axon10x/azure-psm/actions/workflows/validate-workflows.yml/badge.svg)  

![Create Powershell Modules](https://github.com/axon10x/azure-psm/actions/workflows/create-modules.yml/badge.svg)  

## Azure Powershell Module and Scripts

/scripts/ contains mostly Powershell but also Bash scripts. The .ps1 script files can be dot-sourced to use them directly. Due to dependencies, we recommend using the Powershell module instead.

/modules/ contains the axon10.Azure Powershell module with .psm1/.psd1 files. Currently axon10.Azure is built automatically from all the .ps1 files in /scripts/ when a push is made to develop. See the create-modules.yml workflow for details.

The "Create PowerShell modules from script files" workflow runner pushes the built module back to the GitHub repo in the same branch. After the workflow runs, you should `git pull` to get the new module files locally on the same branch. Then you can do your usual CI flow, PRs, etc.

---

### PLEASE NOTE FOR THE ENTIRETY OF THIS REPOSITORY AND ALL ASSETS
#### 1. No warranties or guarantees are made or implied.
#### 2. All assets here are provided "as is". Use at your own risk. Validate before use.
#### 3. We assume no liability whatsoever, and will not provide support, for any use of these assets outside of a contractual engagement with AXON10 LLC.
#### 4. Use of the assets in this repo in your Azure environment may or will incur Azure usage and charges. You are completely responsible for monitoring and managing your Azure usage.

---

Unless otherwise noted, all assets here are original to and authored by AXON10 LLC. Feel free to examine, learn from, comment, and re-use (subject to the above) as needed and without intellectual property restrictions.

If anything here helps you, attribution and/or a quick note is much appreciated.
