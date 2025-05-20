#!/bin/bash

KEY_DIR="/c/keys"
KEY_NAME="id_rsa"
PRIVATE_KEY="$KEY_DIR/$KEY_NAME"
PUBLIC_KEY="$PRIVATE_KEY.pub"

# removeing spaces
read -p "Enter the Ubuntu server IP: " SERVER_IP
SERVER_IP=$(echo "$SERVER_IP" | tr -d '\r' | xargs)

read -p "Enter the SSH username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\r' | xargs)

# MKDIR
if [ ! -d "$KEY_DIR" ]; then
    mkdir -p "$KEY_DIR"
    echo "Created folder: $KEY_DIR"
fi

#Make it if is not there
if [ ! -f "$PRIVATE_KEY" ]; then
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
    echo "SSH key pair generated at $PRIVATE_KEY"
else
    echo "Key already exists, skipping generation"
fi

#Copy the key
if [ -f "$PUBLIC_KEY" ]; then
    echo "Copying public key to server..."
    cat "$PUBLIC_KEY" | ssh "$USERNAME@$SERVER_IP" \
    "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
else
    echo "ERROR: Public key not found at $PUBLIC_KEY"
    exit 1
fi

# Connect by key
echo
echo "Now trying to connect using private key..."
ssh -i "$PRIVATE_KEY" "$USERNAME@$SERVER_IP"
