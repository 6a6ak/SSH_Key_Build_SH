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

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

# Generate key if not exists
if [ ! -f "$PRIVATE_KEY" ]; then
    ssh-keygen -t ed25519 -f "$PRIVATE_KEY" -N ""
    echo "SSH key generated: $PRIVATE_KEY"
else
    echo "Key exists: $PRIVATE_KEY"
fi

chmod 600 "$PRIVATE_KEY"

# Copy key (idempotent)
echo "Copying public key..."
PUB_CONTENT="$(cat "$PUBLIC_KEY")"

ssh "$USERNAME@$SERVER_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
ssh "$USERNAME@$SERVER_IP" "grep -qxF '$PUB_CONTENT' ~/.ssh/authorized_keys 2>/dev/null || echo '$PUB_CONTENT' >> ~/.ssh/authorized_keys"
ssh "$USERNAME@$SERVER_IP" "chmod 600 ~/.ssh/authorized_keys"

# Test connection with key only
echo
echo "Testing key-based SSH..."
if ssh -i "$PRIVATE_KEY" -o BatchMode=yes "$USERNAME@$SERVER_IP" "echo OK" 2>/dev/null; then
    echo "✔ Key auth working"
else
    echo "❌ Key auth failed (check username/password once)"
fi

# Connect
echo
echo "Connecting..."
ssh -i "$PRIVATE_KEY" "$USERNAME@$SERVER_IP"