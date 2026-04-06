#!/bin/bash

KEY_DIR="/c/keys"
KEY_NAME="id_rsa"
PRIVATE_KEY="$KEY_DIR/$KEY_NAME"
PUBLIC_KEY="$PRIVATE_KEY.pub"

# ignore broken ssh config
SSH_OPTS="-F /dev/null"

read -p "Enter server IP: " SERVER_IP
SERVER_IP=$(echo "$SERVER_IP" | tr -d '\r' | xargs)

read -p "Enter SSH username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\r' | xargs)

# create key dir
if [ ! -d "$KEY_DIR" ]; then
    mkdir -p "$KEY_DIR"
    echo "[OK] Created $KEY_DIR"
fi

# generate key if not exists
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "[*] Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
else
    echo "[OK] Key exists"
fi

# fix permissions (optional, ignore error)
echo "[*] Fixing permissions..."
WIN_PATH=$(echo "$PRIVATE_KEY" | sed 's|/|\\|g' | sed 's|^\\c|C:|')
powershell.exe -ExecutionPolicy Bypass -File "fix_permissions.ps1" "$WIN_PATH" 2>/dev/null

# copy public key
if [ -f "$PUBLIC_KEY" ]; then
    echo "[*] Copying key to server..."

    cat "$PUBLIC_KEY" | ssh $SSH_OPTS "$USERNAME@$SERVER_IP" "
        mkdir -p ~/.ssh &&
        chmod 700 ~/.ssh &&
        touch ~/.ssh/authorized_keys &&
        chmod 600 ~/.ssh/authorized_keys &&
        grep -qxF '$(cat $PUBLIC_KEY)' ~/.ssh/authorized_keys || cat >> ~/.ssh/authorized_keys
    "

else
    echo "[ERROR] Public key not found"
    exit 1
fi

# test connection
echo
echo "[*] Testing SSH key login..."
ssh $SSH_OPTS -i "$PRIVATE_KEY" "$USERNAME@$SERVER_IP" "echo '[SUCCESS] SSH key works'"

if [ $? -eq 0 ]; then
    echo "[DONE] You can now connect without password:"
    echo "ssh -i $PRIVATE_KEY $USERNAME@$SERVER_IP"
else
    echo "[ERROR] SSH key login failed"
fi