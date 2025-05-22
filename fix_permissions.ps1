param (
    [string]$KeyPath
)

# get the user
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "Applying permissions for $User on $KeyPath ..."

# acl for file
$acl = Get-Acl -Path $KeyPath

# delet old inputs
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

# read setup for user
$permission = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "Read", "Allow")
$acl.AddAccessRule($permission)

# save ACL
Set-Acl -Path $KeyPath -AclObject $acl

Write-Host "Secure permissions applied successfully."
