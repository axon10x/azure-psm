function New-CosmosDbFailoverPolicy()
{
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )
  $DefinitionName = "audit-cosmosdb-autofailover-georeplication"
  $DefinitionDisplayName = "Audit Automatic Failover for CosmosDB accounts"
  $DefinitionDescription = "This policy audits Automatic Failover for CosmosDB accounts"
  $PolicyUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/samples/CosmosDB/audit-cosmosdb-autofailover-georeplication/azurepolicy.rules.json"
  $ParametersUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/samples/CosmosDB/audit-cosmosdb-autofailover-georeplication/azurepolicy.parameters.json"
  $AssignmentName = ($ResourceGroupName + "-" + $DefinitionName)

  $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName

  $definition = New-AzPolicyDefinition -Name $DefinitionName -DisplayName $DefinitionDisplayName -description $DefinitionDescription -Policy $PolicyUrl -Parameter $ParametersUrl -Mode All
  $definition

  $assignment = New-AzPolicyAssignment -Name $AssignmentName -Scope $ResourceGroup.ResourceId -PolicyDefinition $definition
  $assignment
}
