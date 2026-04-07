#!/bin/bash

KEY_DIR="/c/keys"
KEY_NAME="id_rsa"
PRIVATE_KEY="$KEY_DIR/$KEY_NAME"
PUBLIC_KEY="$PRIVATE_KEY.pub"

SSH_OPTS="-F /dev/null"

read -p "Enter server IP: " SERVER_IP
SERVER_IP=$(echo "$SERVER_IP" | tr -d '\r' | xargs)

read -p "Enter SSH username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\r' | xargs)

read -p "Enter host alias (e.g. opi): " HOST_ALIAS
HOST_ALIAS=$(echo "$HOST_ALIAS" | tr -d '\r' | xargs)

# create key dir
if [ ! -d "$KEY_DIR" ]; then
    mkdir -p "$KEY_DIR"
    echo "[OK] Created $KEY_DIR"
fi

# generate key
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "[*] Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
else
    echo "[OK] Key exists"
fi

# fix permissions (ignore errors)
echo "[*] Fixing permissions..."
WIN_PATH=$(echo "$PRIVATE_KEY" | sed 's|/|\\|g' | sed 's|^\\c|C:|')
powershell.exe -ExecutionPolicy Bypass -File "fix_permissions.ps1" "$WIN_PATH" 2>/dev/null

# copy key safely (FIXED quoting issue)
echo "[*] Copying key to server..."

ssh $SSH_OPTS "$USERNAME@$SERVER_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

cat "$PUBLIC_KEY" | ssh $SSH_OPTS "$USERNAME@$SERVER_IP" "cat >> ~/.ssh/authorized_keys"

ssh $SSH_OPTS "$USERNAME@$SERVER_IP" "chmod 600 ~/.ssh/authorized_keys"

# test connection
echo
echo "[*] Testing SSH key login..."

ssh $SSH_OPTS -i "$PRIVATE_KEY" "$USERNAME@$SERVER_IP" "echo '[SUCCESS] SSH key works'"

if [ $? -ne 0 ]; then
    echo "[ERROR] SSH key login failed"
    exit 1
fi

# --- ADD SSH CONFIG ---
CONFIG_FILE="$HOME/.ssh/config"

echo "[*] Updating SSH config..."

mkdir -p "$HOME/.ssh"

if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
fi

# avoid duplicate
if grep -q "Host $HOST_ALIAS" "$CONFIG_FILE"; then
    echo "[OK] Host '$HOST_ALIAS' already exists"
else
    echo "" >> "$CONFIG_FILE"
    echo "Host $HOST_ALIAS" >> "$CONFIG_FILE"
    echo "    HostName $SERVER_IP" >> "$CONFIG_FILE"
    echo "    User $USERNAME" >> "$CONFIG_FILE"
    echo "    IdentityFile C:/keys/id_rsa" >> "$CONFIG_FILE"
    echo "[OK] Host '$HOST_ALIAS' added"
fi

# final output
echo
echo "[DONE] Setup complete"
echo "Use:"
echo "ssh $HOST_ALIAS"
echo "sftp $HOST_ALIAS"