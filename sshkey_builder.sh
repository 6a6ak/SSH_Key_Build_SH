#!/usr/bin/env bash
set -euo pipefail

if (( $# > 2 )); then
    echo "Usage: bash sshkey_builder.sh [server [username]]" >&2
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

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KEY_DIR="$HOME/.ssh"
PRIVATE_KEY="$KEY_DIR/${SERVER_IP//:/_}"
PUBLIC_KEY="$PRIVATE_KEY.pub"
umask 077
mkdir -p -- "$KEY_DIR"
if [[ ! -f "$PRIVATE_KEY" ]]; then
    if [[ -e "$PUBLIC_KEY" ]]; then
        echo "ERROR: Public key exists without its private key: $PUBLIC_KEY" >&2
        exit 1
    fi
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N ""
else
    echo "Using existing private key: $PRIVATE_KEY"
fi

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        powershell.exe -NoProfile -ExecutionPolicy Bypass \
            -File "$(cygpath -w "$SCRIPT_DIR/fix_permissions.ps1")" \
            "$(cygpath -w "$PRIVATE_KEY")"
        ;;
    *) chmod 600 -- "$PRIVATE_KEY" ;;
esac

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
ssh -i "$PRIVATE_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
    "$USERNAME@$SERVER_IP" 'true'
echo "Key-based login verified. Connecting..."
ssh -i "$PRIVATE_KEY" -o IdentitiesOnly=yes "$USERNAME@$SERVER_IP"
