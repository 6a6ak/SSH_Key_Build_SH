param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$KeyPath
)
$ErrorActionPreference = 'Stop'
try {
    $key = Get-Item -LiteralPath $KeyPath
    if ($key.PSIsContainer) {
        throw 'The private key path must be a file.'
    }
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl = Get-Acl -LiteralPath $key.FullName
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($existingRule in @($acl.Access)) {
        [void]$acl.RemoveAccessRuleSpecific($existingRule)
    }
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $identity, 'FullControl', 'Allow'
    )
    $acl.AddAccessRule($rule)
    [System.IO.File]::SetAccessControl($key.FullName, $acl)
} catch {
    Write-Error $_
    exit 1
}
