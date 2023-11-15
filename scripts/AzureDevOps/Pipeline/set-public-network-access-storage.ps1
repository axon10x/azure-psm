param
(
  [string]$StorageAccountName,
  [string]$DefaultAction # Allow or Deny
)

az storage account update --name $StorageAccountName --default-action $DefaultAction
