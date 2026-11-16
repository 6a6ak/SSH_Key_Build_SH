#!/usr/bin/env bash
set -euo pipefail

if (( $# > 3 )); then
    echo "Usage: bash sshkey_builder.sh [server [username [key-name]]]" >&2
    exit 1
fi
SERVER_IP=${1:-}
USERNAME=${2:-}
if [[ -z "$SERVER_IP" ]]; then
    read -rp "Enter the Ubuntu server IP or hostname: " SERVER_IP
fi
if [[ -z "$USERNAME" ]]; then
    read -rp "Enter the SSH username: " USERNAME
fi
SERVER_IP=${SERVER_IP//$'\r'/}
USERNAME=${USERNAME//$'\r'/}
if [[ ! "$SERVER_IP" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]] ||
   [[ ! "$USERNAME" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*\$?$ ]]; then
    echo "ERROR: Invalid server address or username." >&2
    exit 1
fi

KEY_NAME=${3:-}
if [[ -z "$KEY_NAME" ]]; then
    read -rp "Enter a name for the key (letters, digits, hyphens, underscores): " KEY_NAME
fi
KEY_NAME=${KEY_NAME%$'\r'}
if [[ ! "$KEY_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$ ]] ||
   [[ "${KEY_NAME^^}" =~ ^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$ ]]; then
    echo "ERROR: Invalid key name. Choose a filename with up to 80 letters, digits, hyphens, or underscores." >&2
    exit 1
fi

KEY_DIR="$HOME/.ssh"
PRIVATE_KEY="$KEY_DIR/$KEY_NAME"
PUBLIC_KEY="$PRIVATE_KEY.pub"
umask 077
mkdir -p -- "$KEY_DIR"
if [[ ! -f "$PRIVATE_KEY" ]]; then
    if [[ -e "$PUBLIC_KEY" ]]; then
        echo "ERROR: Public key exists without its private key: $PUBLIC_KEY" >&2
        exit 1
    fi
    protect_key=n
    if [[ -t 0 ]]; then
        read -rp "Protect the new private key with a passphrase? [y/N] " protect_key
    fi
    case "$protect_key" in
        y|Y|yes|YES|Yes) ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" ;;
        ""|n|N|no|NO|No) ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" ;;
        *) echo "ERROR: Enter yes or no." >&2; exit 1 ;;
    esac
else
    echo "Using existing private key: $PRIVATE_KEY"
fi

chmod 600 -- "$PRIVATE_KEY"

# Derive the public key to recover missing or stale public files.
PUBLIC_TEMP=$(mktemp "$KEY_DIR/.public-key.XXXXXX")
trap 'rm -f -- "$PUBLIC_TEMP"' EXIT
ssh-keygen -y -f "$PRIVATE_KEY" > "$PUBLIC_TEMP"
mv -f -- "$PUBLIC_TEMP" "$PUBLIC_KEY"

echo "Installing public key on $SERVER_IP..."
ssh -i "$PRIVATE_KEY" -o IdentitiesOnly=yes "$USERNAME@$SERVER_IP" '
    set -eu
    umask 077
    IFS= read -r key
    test -n "$key"
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    if ! awk -v key="$key" '\''
        BEGIN { split(key, parts, " ") }
        { for (i = 1; i < NF; i++)
            if ($i == parts[1] && $(i + 1) == parts[2]) found = 1 }
        END { exit !found }
    '\'' ~/.ssh/authorized_keys; then
        printf "\n%s\n" "$key" >> ~/.ssh/authorized_keys
    fi
' < "$PUBLIC_KEY"

echo "Verifying key-based login..."
ssh -i "$PRIVATE_KEY" -o IdentitiesOnly=yes -o BatchMode=no \
    -o PreferredAuthentications=publickey \
    "$USERNAME@$SERVER_IP" 'true'
echo "Key-based login verified. Connecting..."
ssh -i "$PRIVATE_KEY" -o IdentitiesOnly=yes "$USERNAME@$SERVER_IP"
