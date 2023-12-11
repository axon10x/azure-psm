function New-AzureContainerRegistryImage()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $RegistryName,
    [Parameter(Mandatory=$true)]
    [string]
    $ImageName,
    [Parameter(Mandatory=$true)]
    [string]
    $Version
  )
  Write-Debug -Debug:$debug -Message "New-AzureContainerRegistryImage $ImageName/$Version"

  $registry = $RegistryName.ToLowerInvariant()
  $baseImage = $registry + ".azurecr.io/" + $ImageName
  $versionedImage = $baseImage + ":" + $Version
  $latestImage = $baseImage + ":latest"

  $dockerBuildCmd = "docker build -f Dockerfile -t $versionedImage -t $latestImage ."
  Write-Debug -Debug:$debug -Message "dockerBuildCmd: $dockerBuildCmd"
  Invoke-Expression $dockerBuildCmd

  $dockerPushCmd = "docker image push --all-tags $baseImage"
  Write-Debug -Debug:$debug -Message "dockerPushCmd: $dockerPushCmd"
  Invoke-Expression $dockerPushCmd
}

function Set-AzureContainerRegistryAdminUserEnabled()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $RegistryName,
    [Parameter(Mandatory=$true)]
    [bool]
    $AdminUserEnabled
  )
  Write-Debug -Debug:$debug -Message "Set-AzureContainerRegistryAdminUserEnabled $RegistryName/$AdminUserEnabled"

  $output = az acr update `
    -g $ResourceGroupName `
    -n $RegistryName `
    --admin-enabled $AdminUserEnabled `
    | ConvertFrom-Json

  Write-Debug -Debug:$debug -Message $output
}

function Set-AzureContainerRegistryImageToAppService()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $AppServiceName,
    [Parameter(Mandatory=$true)]
    [string]
    $RegistryName,
    [Parameter(Mandatory=$true)]
    [string]
    $ImageName,
    [Parameter(Mandatory=$false)]
    [string]
    $Version = "latest"
  )
  Write-Debug -Debug:$debug -Message "Set-AzureContainerRegistryImageToAppService $RegistryName/$ImageName/$Version"

  $acrFqdn = "$RegistryName.azurecr.io"
  $acrUrl = "https://$acrFqdn"
  $image = "$acrFqdn" + "/" + "$ImageName" + ":" + "$Version"

  az webapp config container set `
    -g $ResourceGroupName `
    -n $AppServiceName `
    --docker-registry-server-url $acrUrl `
    --docker-custom-image-name $image
}

function Set-AzureContainerRegistryPublicNetworkAccess()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $RegistryName,
    [Parameter(Mandatory=$true)]
    [bool]
    $PublicNetworkEnabled,
    [Parameter(Mandatory=$false)]
    [string]
    $DefaultAction = "Deny"
  )
  Write-Debug -Debug:$debug -Message "Set-AzureContainerRegistryPublicNetworkAccess $RegistryName/$PublicNetworkEnabled"

  $output = az acr update `
    -g $ResourceGroupName `
    -n $RegistryName `
    --public-network-enabled $PublicNetworkEnabled `
    --default-action $DefaultAction `
    | ConvertFrom-Json

  Write-Debug -Debug:$debug -Message $output
}

function Set-AzureContainerRegistryNetworkRule()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $RegistryName,
    [Parameter(Mandatory=$true)]
    [string]
    $IpAddressRange,
    [Parameter(Mandatory=$false)]
    [string]
    $Action = "Remove"
  )
  Write-Debug -Debug:$debug -Message "Set-AzureContainerRegistryNetworkRule $RegistryName/$IpAddressRange/$Action"

  if ($Action.ToLowerInvariant() -eq "add")
  {
    $output = az acr network-rule add `
      -g $ResourceGroupName `
      -n $RegistryName `
      --ip-address $IpAddressRange `
      | ConvertFrom-Json
  }
  else
  {
    $output = az acr network-rule remove `
      -g $ResourceGroupName `
      -n $RegistryName `
      --ip-address $IpAddressRange `
      | ConvertFrom-Json
  }

  Write-Debug -Debug:$debug -Message $output
}