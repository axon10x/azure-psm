function Set-SyncServiceBusNamespaceKeys()
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
    $NamespaceNameSource,
    [Parameter(Mandatory = $true)]
    [string]
    $NamespaceNameDestination,
    [Parameter(Mandatory = $false)]
    [string]
    $SasPolicyName = "RootManageSharedAccessKey"
  )

  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Network Rule for $VNetName and $SubnetName"

  # This script synchronizes Azure Service Bus namespace keys from a source to a destination namespace.
  # Why use this? In case you have a scenario (e.g. active/active or active/passive) and you cannot refer to each namespace by individual connection string or key.
  # Example: JMS client failover-enabled connection string does not allow for specification of individual keys for each targeted namespace; only one key can be specified.

  # Source namespace RootManageSharedAccessKey
  primaryKey="$(az servicebus namespace authorization-rule keys list --subscription "$SubscriptionId" -g "$ResourceGroupName" --namespace-name "$NamespaceNameSource" -n "$SasPolicyName" -o tsv --query 'primaryKey')"
  secondaryKey="$(az servicebus namespace authorization-rule keys list --subscription "$SubscriptionId" -g "$ResourceGroupName" --namespace-name "$NamespaceNameSource" -n "$SasPolicyName" -o tsv --query 'secondaryKey')"

  # Set to destination namespace
  az servicebus namespace authorization-rule keys renew --subscription "$SubscriptionId" --verbose `
    -g "$ResourceGroupName" --namespace-name "$NamespaceNameDestination" -n "$SasPolicyName" `
    --key PrimaryKey --key-value "$primaryKey"

  az servicebus namespace authorization-rule keys renew --subscription "$SubscriptionId" --verbose `
    -g "$ResourceGroupName" --namespace-name "$NamespaceNameDestination" -n "$SasPolicyName" `
    --key SecondaryKey --key-value "$secondaryKey"
}