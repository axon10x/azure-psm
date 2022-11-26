# See the readme and edit globals.ps1 before running this script.
.\globals.ps1

function DoResourceGroup()
{
  param
  (
    [string]$ResourceGroupName,
    [string]$AzureRegion
  )

  $rg = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion -ErrorAction SilentlyContinue

  if ($null -eq $rg) {
    Write-Host("Creating Resource Group " + $ResourceGroupName + " in region " + $AzureRegion)

    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion

    $rg = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion -ErrorAction SilentlyContinue
  }
  else {
    Write-Host("Found/using existing Resource Group " + $ResourceGroupName + " in region " + $AzureRegion)
  }

  return $rg
}

# Network resource groups
if ($g_DeployBastion) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameNetworkBastion -AzureRegion $g_AzureRegionBastion}
if ($g_DeployCluster1) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameNetworkRegion1 -AzureRegion $g_AzureRegion1}
if ($g_DeployCluster2) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameNetworkRegion2 -AzureRegion $g_AzureRegion2}
if ($g_DeployCluster3) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameNetworkRegion3 -AzureRegion $g_AzureRegion3}

# Storage resource groups
if ($g_DeployBastion) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameStorageBastion -AzureRegion $g_AzureRegionBastion}
if ($g_DeployCluster1) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameStorageRegion1 -AzureRegion $g_AzureRegion1}
if ($g_DeployCluster2) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameStorageRegion2 -AzureRegion $g_AzureRegion2}
if ($g_DeployCluster3) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameStorageRegion3 -AzureRegion $g_AzureRegion3}

# VM resource groups
if ($g_DeployBastion) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameVMsBastion -AzureRegion $g_AzureRegionBastion}
if ($g_DeployCluster1) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameVMsCluster1 -AzureRegion $g_AzureRegion1}
if ($g_DeployCluster2) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameVMsCluster2 -AzureRegion $g_AzureRegion2}
if ($g_DeployCluster3) {DoResourceGroup -ResourceGroupName $g_ResourceGroupNameVMsCluster3 -AzureRegion $g_AzureRegion3}
