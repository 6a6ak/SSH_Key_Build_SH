# SSH Key Builder

Set up key-based login from your computer to an Ubuntu SSH server.

The script creates an RSA 4096-bit key pair on your computer, installs the public
key on the server, verifies key-based authentication, and opens an SSH session.
The private key stays on your computer.

## Before you start

- On Windows, install [Git for Windows](https://gitforwindows.org/), which includes Git Bash.
- On Linux/macOS, use Bash with OpenSSH client tools installed.
- Have the server's address, SSH username, and initial login credentials ready.
- Open a terminal in the project folder. Paste the commands below into that terminal.

## Run on Windows

### From PowerShell or a VS Code PowerShell terminal

Use Git Bash explicitly. This example assumes Git is installed in its default location.

```powershell
& "C:\Program Files\Git\bin\bash.exe" ./sshkey_builder.sh
```

To supply the server address and username directly:

```powershell
& "C:\Program Files\Git\bin\bash.exe" ./sshkey_builder.sh server.example.com ubuntu office_key
```

### From Git Bash

```bash
bash sshkey_builder.sh
```

## Run on Linux/macOS

```bash
bash sshkey_builder.sh
# Or supply the server address and username:
bash sshkey_builder.sh server.example.com ubuntu office_key
```

## What to expect

1. Enter the server address and username if you omitted them from the command.
2. The script creates a key pair or reuses the existing private key for that server.
3. On a first connection, SSH may ask you to confirm the server's host key.
   Confirm after checking the fingerprint against your server's trusted information.
4. Enter the server account's password if requested. Password characters are hidden
   while you type.
5. The script installs the public key, verifies key-based login, and opens a session.
   Run `exit` to return to your local terminal.

## Where are my keys?

Keys are saved under `~/.ssh/`, using the server address as the filename.
With the default Git Bash home directory on Windows, a server named
Enter a key name when prompted, or pass it as the third argument. The name
`office_key` identifies a key for the office server and produces these files.
The same name appears as the comment at the end of the public key.

| File | Default Windows location | Purpose |
| --- | --- | --- |
| Private key | `C:\Users\<WindowsUsername>\.ssh\office_key` | Used locally to authenticate. Keep it private. |
| Public key | `C:\Users\<WindowsUsername>\.ssh\office_key.pub` | Installed on the server. |

To open the default key folder from PowerShell:

```powershell
explorer "$env:USERPROFILE\.ssh"
```

If you customized Git Bash's home directory, run `echo "$HOME/.ssh"` in Git Bash
to see the actual folder. Linux/macOS also use `~/.ssh/`.
IPv6 colons in key filenames become underscores.

## Connect again

From Git Bash or a Linux/macOS terminal:

```bash
ssh -i ~/.ssh/office_key -o IdentitiesOnly=yes ubuntu@server.example.com
```

Replace the example address and username with the values you used during setup.

## Troubleshooting

### WSL reports that `/bin/bash` could not be started

If PowerShell shows `execvpe /bin/bash failed`, its `bash` command is launching
Windows Subsystem for Linux. Run the explicit Git Bash command shown in the
Windows instructions above.

### The Git Bash executable cannot be found

Check that Git for Windows is installed. If you installed it in another folder,
adjust the executable path, or open Git Bash directly in the project folder.

## Key handling

Existing private keys are reused. Missing or stale public keys are regenerated
from the private key.

When creating a key in a terminal, choose whether to set a passphrase. Answer
yes and enter and confirm a nonempty passphrase at the OpenSSH prompts. Press
Enter at the yes/no prompt to create a key without a passphrase. Noninteractive
runs also create new keys without a passphrase.

OpenSSH may prompt to unlock an encrypted key when deriving the public key,
verifying login, or connecting. Login verification uses public-key
authentication only.

The script applies file mode 600 to the private key using chmod.

The server's authorized_keys file preserves existing entries. Matching key type
and data prevent duplicate installation, including entries with comments or
options. Avoid simultaneous installations for the same server account.

Initial installation may prompt for the server password and host-key confirmation.
The script verifies key authentication using BatchMode=yes, then opens an
interactive SSH session. Errors stop execution with a nonzero exit status.

## Local regression checks

```bash
bash tests/test_builder.sh
```

Checks generate real temporary keys and execute the
server installation command in a temporary local home through an SSH test double.
A real network connection requires separate server access.
