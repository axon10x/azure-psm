function Get-PolicyAliases()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $NamespaceMatch
  )

  Get-AzPolicyAlias -NamespaceMatch "NamespaceMatch" | Select-Object namespace, resourcetype -ExpandProperty aliases
}

function Get-PolicyInfo()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId
  )

  # Get custom policy definitions
  $definitions = Get-AzPolicyDefinition -SubscriptionId $SubscriptionId -Custom

  # Get policy state summary for each custom policy definition
  ForEach ($definition in $definitions)
  {
    Write-Debug -Debug:$debug -Message "Policy State Summary"
    Get-AzPolicyStateSummary -SubscriptionId $SubscriptionId -PolicyDefinitionName $definition.Name

    Write-Debug -Debug:$debug -Message "Policy Assignments"
    $assignments = Get-AzPolicyAssignment -PolicyDefinitionId $definition.PolicyDefinitionId

    ForEach ($assignment in $assignments) {
      Write-Debug -Debug:$debug -Message "Policy State for the Policy Assignment"
      Get-AzPolicyState -SubscriptionId $SubscriptionId -PolicyAssignmentName $assignment.Name
    }
  }
}

function New-PolicyAssignment()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $PolicyDefinitionName,
    [Parameter(Mandatory = $true)]
    [string]
    $AssignmentName,
    [Parameter(Mandatory = $true)]
    [string]
    $DisplayName,
    [Parameter(Mandatory = $true)]
    [string]
    $ParameterName,
    [Parameter(Mandatory = $true)]
    [string]
    $ParameterValue
  )

  # Get the resource group ID so we can set it as policy assignment audit scope
  # Scope can also be subscription or management group.
  $resource_group_id = (Get-AzResourceGroup -Name $ResourceGroupName).ResourceId

  # Get the policy definition for input to policy assignment
  $definition = Get-AzPolicyDefinition -Name $PolicyDefinitionName

  # Prepare parameter input object
  $parameter = @{$ParameterName = $ParameterValue}

  # Assign policy
  New-AzPolicyAssignment `
    -Name $AssignmentName `
    -DisplayName $DisplayName `
    -Scope $resource_group_id `
    -PolicyDefinition $definition `
    -PolicyParameterObject $parameter
}

function New-PolicyDefinition()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $PolicyDefinitionName,
    [Parameter(Mandatory = $true)]
    [string]
    $Category,
    [Parameter(Mandatory = $true)]
    [string]
    $DisplayName,
    [Parameter(Mandatory = $true)]
    [string]
    $Description,
    [Parameter(Mandatory = $true)]
    [string]
    $RulesUrl,
    [Parameter(Mandatory = $true)]
    [string]
    $ParamsUrl
  )

  # Create policy definition
  New-AzPolicyDefinition `
    -Name $PolicyDefinitionName `
    -Metadata ('{"category":"' + $Category + '"}') `
    -DisplayName $DisplayName `
    -Description $Description `
    -Policy $RulesUrl `
    -Parameter $ParamsUrl `
    -Mode All
}