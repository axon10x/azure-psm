function Get-CleanKeyVaultSecretName()
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

function Set-KeyVaultSecret()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $keyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $rawSecretName,
    [Parameter(Mandatory=$true)]
    [string]
    $rawSecretValue
  )
  $secretName = Get-CleanKeyVaultSecretName -VarName "$rawSecretName"
  $secretValue = ConvertTo-SecureString "$rawSecretValue" -AsPlainText -Force

  Set-AzKeyVaultSecret -VaultName "$keyVaultName" -Name "$secretName" -SecretValue $secretValue
}