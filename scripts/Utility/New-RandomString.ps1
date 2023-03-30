Function New-RandomString
{
  Param ([Int]$Length = 10)

  return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))
}