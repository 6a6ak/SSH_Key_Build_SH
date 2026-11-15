# SSH Key Builder

Generate an RSA 4096-bit key and install its public key on an Ubuntu SSH server.
Requires Git Bash and PowerShell on Windows, or Bash on Linux/macOS, plus OpenSSH
client tools and initial SSH access to the server.

## Usage

```bash
bash sshkey_builder.sh
bash sshkey_builder.sh server.example.com ubuntu
```

Missing arguments are prompted for once. Keys are stored in ~/.ssh using the
server address as the filename. IPv6 colons become underscores. Existing private
keys are reused. Missing or stale public keys are regenerated.

New keys have an empty passphrase. Protect your private key. Existing encrypted
keys prompt during public-key derivation and require an SSH agent for batch-mode
verification.

The included fix_permissions.ps1 limits private-key access to the current Windows
user. The helper is found relative to the script. Linux/macOS use file mode 600.

The server's authorized_keys file preserves existing entries. Matching key type
and data prevent duplicate installation, including entries with comments or
options. Avoid simultaneous installations for the same server account.

Initial installation may prompt for the server password and host-key confirmation.
The script verifies key authentication using BatchMode=yes, then opens an
interactive SSH session. Errors stop execution with a nonzero exit status.
There are no separate automation or icon modes.

## Local regression checks

```bash
bash tests/test_builder.sh
```

Checks generate real temporary keys, apply Windows permissions, and execute the
server installation command in a temporary local home through an SSH test double.
A real network connection requires separate server access.