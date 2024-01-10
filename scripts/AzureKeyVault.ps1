function Deploy-KeyVault()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $KeyVaultName,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForDeployment = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForDiskEncryption = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForTemplateDeployment = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableSoftDelete = $false,
    [Parameter(Mandatory = $false)]
    [int]
    $SoftDeleteRetentionInDays = 7,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableRbacAuthorization = $true,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedIpAddressRangesCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedSubnetResourceIdsCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Key Vault $KeyVaultName"

  $tagsForTemplate = Get-TagsForArmTemplate -Tags $Tags

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$KeyVaultName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    tenantId="$TenantId" `
    keyVaultName="$KeyVaultName" `
    enabledForDeployment="$EnabledForDeployment" `
    enabledForDiskEncryption="$EnabledForDiskEncryption" `
    enabledForTemplateDeployment="$EnabledForTemplateDeployment" `
    enableSoftDelete="$EnableSoftDelete" `
    softDeleteRetentionInDays="$SoftDeleteRetentionInDays" `
    enableRbacAuthorization="$EnableRbacAuthorization" `
    publicNetworkAccess="$PublicNetworkAccess" `
    defaultAction="$DefaultAction" `
    allowedIpAddressRanges="$AllowedIpAddressRangesCsv" `
    allowedSubnetResourceIds="$AllowedSubnetResourceIdsCsv" `
    tags=$tagsForTemplate `
    | ConvertFrom-Json

  return $output
}

function Get-KeyVaultSecret()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $KeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretName
  )
  Write-Debug -Debug:$true -Message "Get Key Vault $KeyVaultName Secret $SecretName"

  $secretValue = ""

  if ($SecretName)
  {
    $secretNameSafe = Get-KeyVaultSecretName -VarName "$SecretName"

    $secretValue = az keyvault secret show `
      --subscription "$SubscriptionId" `
      --vault-name "$KeyVaultName" `
      --name "$secretNameSafe" `
      -o tsv `
      --query 'value' 2>&1

    if (!$?)
    {
      $secretValue = ""
    }
  }

  return $secretValue
}

function Get-KeyVaultSecretName()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $VarName
  )
  # Fix KV secret name; only - and alphanumeric allowed
  $secretName = $VarName.Replace(":", "-").Replace("_", "-")

  return $secretName
}

function New-KeyVaultNetworkRuleForIpAddressOrRange()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $IpAddressOrRange
  )

  Write-Debug -Debug:$true -Message "Add Key Vault $KeyVaultName Network Rule for $IpAddressOrRange"

  $output = az keyvault network-rule add `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --ip-address "$IpAddressOrRange" `
    | ConvertFrom-Json

  return $output
}

function New-KeyVaultNetworkRuleForVnetSubnet()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetName
  )

  Write-Debug -Debug:$true -Message "Add Key Vault $KeyVaultName Network Rule for $VNetName and $SubnetName"

  $output = az keyvault network-rule add `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --vnet-name "$VNetName" `
    --subnet "$SubnetName" `
    | ConvertFrom-Json

  return $output
}

function Remove-KeyVaultNetworkRuleForIpAddressOrRange()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $IpAddressOrRange
  )

  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Network Rule for $IpAddressOrRange"

  $output = az keyvault network-rule remove `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --ip-address "$IpAddressOrRange" `
    | ConvertFrom-Json

  return $output
}

function Remove-KeyVaultNetworkRuleForVnetSubnet()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetName
  )

  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Network Rule for $VNetName and $SubnetName"

  $output = az keyvault network-rule remove `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --vnet-name "$VNetName" `
    --subnet "$SubnetName" `
    | ConvertFrom-Json

  return $output
}

function Remove-KeyVaultSecret()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $KeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretName
  )
  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Secret $SecretName"

  if ($SecretName)
  {
    $secretNameSafe = Get-KeyVaultSecretName -VarName "$SecretName"

    $output = az keyvault secret delete `
      --subscription "$SubscriptionId" `
      --vault-name "$KeyVaultName" `
      --name "$secretNameSafe" `
      | ConvertFrom-Json
  }

  return $output
}

function Set-KeyVaultNetworkSettings()
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
    $KeyVaultName,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny"
  )

  Write-Debug -Debug:$true -Message "Set Key Vault $KeyVaultName Network Settings: PublicNetworkAccess=$PublicNetworkAccess, DefaultAction=$DefaultAction"

  $output = az keyvault update `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --public-network-access "$PublicNetworkAccess" `
    --default-action "$DefaultAction" `
    --bypass AzureServices `
    | ConvertFrom-Json

  return $output
}

function Set-KeyVaultSecret()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $KeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretValue
  )
  Write-Debug -Debug:$true -Message "Set Key Vault $KeyVaultName Secret $SecretName"

  $secretNameSafe = Get-KeyVaultSecretName -VarName "$SecretName"

  az keyvault secret set `
    --vault-name "$KeyVaultName" `
    --name "$secretNameSafe" `
    --value "$SecretValue" `
    --output none
}
