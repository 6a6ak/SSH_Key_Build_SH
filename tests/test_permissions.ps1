param([string]$KeyPath)
$ErrorActionPreference = 'Stop'
$acl = Get-Acl -LiteralPath $KeyPath
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if (-not $acl.AreAccessRulesProtected) {
    throw 'Private key permissions still inherit access.'
}
$rules = @($acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier]))
if ($rules.Count -ne 1 -or $rules[0].IdentityReference.Value -ne $identity -or
    $rules[0].AccessControlType -ne 'Allow' -or
    $rules[0].FileSystemRights -ne 'FullControl') {
    throw 'Private key access is not restricted to the current user.'
}
