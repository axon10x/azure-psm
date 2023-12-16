function Remove-DataFactoriesByAge()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionName,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [int]
    $DaysOlderThan
  )

  Write-Debug -Debug:$true -Message "Setting subscription to $SubscriptionName"
  az account set -s $SubscriptionName

  $query = "[].{Name: name, CreateTime: createTime}"
  $factories = $(az datafactory list -g $ResourceGroupName --query $query) | ConvertFrom-Json

  $daysBack = -1 * [Math]::Abs($DaysOlderThan) # Just in case someone passes a negative number to begin with
  $compareDate = (Get-Date).AddDays($daysBack)

  foreach ($factory in $factories)
  {
    $deleteThis = ($compareDate -gt [DateTime]$factory.CreateTime)

    if ($deleteThis)
    {
      Write-Debug -Debug:$true -Message ("Deleting factory " + $factory.Name)
      az datafactory delete -g $ResourceGroupName -n $factory.Name --yes
    }
    else
    {
      Write-Debug -Debug:$true -Message ("No Op on factory " + $factory.Name)
    }
  }
}
