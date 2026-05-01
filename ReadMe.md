# 🔐 SSH Key Builder & Deployment Tool (Windows → Ubuntu)

This repository provides a small script to generate an SSH key pair and install the public
key on an Ubuntu server for passwordless login.

Features:
- Generate a private/public key pair on Windows via Git Bash
- Secure private key file permissions using `fix_permissions.ps1`
- Append the public key to `~/.ssh/authorized_keys` on the remote server (idempotent)
- Attempt a key-based SSH connection automatically

Modes (concepts added):
- `ai` — automated / non-interactive: suitable for scripted or CI runs; minimizes prompts and
	emits diagnostic output for integration.
- `iconic` — interactive: suitable for manual terminal use with friendly icons and confirmations
	(e.g. ✓ / ✖).

Requirements:
- Windows with Git Bash
- PowerShell (default on Windows 10/11)
- Remote Ubuntu server with SSH enabled and initial credentials for first-time setup

File structure:
```
project-root/
├── sshkey_builder.sh       # Main script (run from Git Bash)
└── fix_permissions.ps1     # PowerShell script to set secure file permissions
```

How it works (summary):
1. Prompts for server address/hostname and SSH username.
2. Ensures the local `~/.ssh` directory exists.
3. Generates a key pair with `ssh-keygen` if needed.
4. Optionally secure the private key with `fix_permissions.ps1`.
5. Appends the public key to the server's `~/.ssh/authorized_keys` (avoids duplicates).
6. Attempts a passwordless SSH login using the new key.

Example usage:
```bash
# Run from Git Bash on Windows:
bash sshkey_builder.sh

# Test manually:
ssh -i ~/.ssh/<your-key-name> username@server-ip

# Reapply permissions if needed:
powershell.exe -ExecutionPolicy Bypass -File fix_permissions.ps1 "C:\path\to\private_key"
```

Security notes:
- Protect your private keys and use appropriate paths/names.
- This tool is better suited for secure/internal networks; exercise caution in public environments.

If you want, I can:
- Add a CLI option to select `ai` or `iconic` mode and implement differing behaviors.

License: MIT