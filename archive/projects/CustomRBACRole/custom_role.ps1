$subscriptionId = "PROVIDE"
$subscriptionScope = "/subscriptions/$subscriptionId"
$roleNameBase = "DevTest Labs User"
$roleNameCustom = "DevTest Labs User with VM Control"

$customRoleDef = (Get-AzRoleDefinition $roleNameBase)
$customRoleDef.Id = $null
$customRoleDef.Name = $roleNameCustom
$customRoleDef.IsCustom = $true
$customRoleDef.AssignableScopes.Clear()
$customRoleDef.AssignableScopes.Add($subscriptionScope)
$customRoleDef.Actions.Add("Microsoft.DevTestLab/labs/virtualMachines/Start/action")
$customRoleDef.Actions.Add("Microsoft.DevTestLab/labs/virtualMachines/Stop/action")
$customRoleDef.Actions.Add("Microsoft.DevTestLab/labs/virtualMachines/Restart/action")
$customRoleDef = (New-AzRoleDefinition -Role $customRoleDef)

(Get-AzRoleDefinition $roleNameCustom).Actions
