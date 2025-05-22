# 🔐 SSH Key Builder & Deployment Tool (Windows → Ubuntu)

This project provides a simple automated solution to:

- Create SSH key pairs on a Windows machine using Git Bash
- Set secure permissions for private keys using PowerShell
- Copy the public key to a remote Ubuntu server
- Enable passwordless login via SSH

## 🚀 Features

- Auto-creates `id_rsa` and `id_rsa.pub` under `C:\keys`
- Uses a robust PowerShell script to apply correct file permissions
- Sends public key to the target Ubuntu server via `authorized_keys`
- Automatically attempts a secure SSH connection using the new key

## 🛠 Requirements

- Windows OS with Git Bash installed
- PowerShell (default on Windows 10/11)
- Remote Ubuntu server with:
  - SSH enabled
  - Valid user credentials for first-time access

## 📂 File Structure

```
project-root/
├── sshkey_builder.sh       # Main script (run from Git Bash)
└── fix_permissions.ps1     # PowerShell script for file permissions
```

## 🧪 How It Works

### Step-by-step breakdown of `sshkey_builder.sh`:

1. **Prompt for Server Info**:
    - Read IP and username input

2. **Ensure SSH Key Folder Exists**:
    - Creates `C:\keys` if not present

3. **Generate SSH Key Pair If Needed**:
    - Uses `ssh-keygen` to create `id_rsa` and `id_rsa.pub`

4. **Fix Key Permissions (via PowerShell)**:
    - Calls `fix_permissions.ps1` with the path to the private key

5. **Copy Public Key to Remote Ubuntu Server**:
    - Appends public key to `~/.ssh/authorized_keys`

6. **Connect via SSH Without Password**:
    - Attempts passwordless login using the private key

## ⚙️ `fix_permissions.ps1` Explained

The PowerShell script performs:

- Disables inherited permissions
- Clears existing ACLs
- Grants `Read` permission **only** to the current user

## 🤖 Prompts After Tool Is Built

```bash
# Start the tool:
bash sshkey_builder.sh

# Manually test SSH connection:
ssh -i /c/keys/id_rsa ubuntu@<your-ip>

# Reapply permissions manually (if needed):
powershell.exe -ExecutionPolicy Bypass -File fix_permissions.ps1 "C:\keys\id_rsa"
```

## 📌 Notes

- Ensure `~/.ssh/authorized_keys` on Ubuntu server has correct contents and permissions.
- This setup configures passwordless login only for the specified user and key.
- Best used in secure or internal environments.

## 📄 License

MIT License – use, modify, improve freely.