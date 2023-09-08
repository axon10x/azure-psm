This folder contains both Azure Powershell and Azure CLI bash scripts to create a custom RBAC role in your Azure subscription.

The examples here create a custom role to allow Azure users in the DevTest Users role, who are NOT in Contributor or Owner, to start, stop and restart Lab VMs. Normally, users in DevTest Users can only start/stop/restart VMs they created themselves.

References:

- https://docs.microsoft.com/en-us/azure/lab-services/devtest-lab-add-devtest-user#actions-that-can-be-performed-in-each-role
- https://docs.microsoft.com/en-us/azure/lab-services/devtest-lab-grant-user-permissions-to-specific-lab-policies#creating-a-lab-custom-role-using-powershell
- https://docs.microsoft.com/en-us/cli/azure/role/definition?view=azure-cli-latest
