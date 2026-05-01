#!/bin/bash
set -euo pipefail

# Modes (informational comments):
# - ai: automated / "intelligent" mode
#     - Description: non-interactive/automated mode suitable for CI or automation.
#     - Behavior: minimizes prompts, prints diagnostic output, and is suitable for integration
#       with CI/CD or remote management tooling.
# - iconic: interactive / "iconic" mode
#     - Description: interactive, user-friendly mode with icons and confirmations (e.g. ✓ or ✖).
#     - Behavior: designed for manual terminal use; outputs more human-readable, step-by-step messages.
#
# Note: This script currently only contains explanatory comments for these modes and does not
# implement different runtime behavior. If you'd like, I can add a CLI option or environment
# variable to select modes and adjust prompts/output accordingly.

read -rp "Enter the Ubuntu server IP or hostname: " SERVER_IP
SERVER_IP="$(echo "$SERVER_IP" | tr -d '\r' | xargs)"

read -rp "Enter the SSH username (e.g. telemetry): " USERNAME
USERNAME="$(echo "$USERNAME" | tr -d '\r' | xargs)"

KEY_DIR="$HOME/.ssh"
KEY_NAME="$SERVER_IP"
PRIVATE_KEY="$KEY_DIR/$KEY_NAME"
PUBLIC_KEY="$PRIVATE_KEY.pub"

# get the IP
read -p "Enter the Ubuntu server IP: " SERVER_IP
SERVER_IP=$(echo "$SERVER_IP" | tr -d '\r' | xargs)

read -p "Enter the SSH username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\r' | xargs)

#MKDIR
if [ ! -d "$KEY_DIR" ]; then
    mkdir -p "$KEY_DIR"
    echo "Created folder: $KEY_DIR"
fi

#key maker
if [ ! -f "$PRIVATE_KEY" ]; then
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
    echo "SSH key pair generated at $PRIVATE_KEY"
else
    echo "Key already exists, skipping generation"
fi

#permission for powershell
echo "Fixing permissions via PowerShell..."
WIN_PATH=$(echo "$PRIVATE_KEY" | sed 's|/|\\|g' | sed 's|^\\c|C:|')
powershell.exe -ExecutionPolicy Bypass -File "fix_permissions.ps1" "$WIN_PATH"

# copy public key to server
if [ -f "$PUBLIC_KEY" ]; then
    echo "Copying public key to server..."
    cat "$PUBLIC_KEY" | ssh "$USERNAME@$SERVER_IP" \
    "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
else
    echo "ERROR: Public key not found at $PUBLIC_KEY"
    exit 1
fi

# if ssh key login
echo
echo "Now trying to connect using private key..."
ssh -i "$PRIVATE_KEY" "$USERNAME@$SERVER_IP"
