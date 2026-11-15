#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEMP_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEMP_ROOT"' EXIT
export HOME="$TEMP_ROOT/client home"
export TEST_REMOTE="$TEMP_ROOT/server"
export TEST_LOG="$TEMP_ROOT/ssh.log"
mkdir -p "$HOME" "$TEST_REMOTE/.ssh" "$TEMP_ROOT/bin"
printf 'existing-key-without-newline' > "$TEST_REMOTE/.ssh/authorized_keys"
cat > "$TEMP_ROOT/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$TEST_LOG"
if [[ "$*" == *BatchMode=yes* ]]; then
    exit "${TEST_VERIFY_EXIT:-0}"
fi
last="${!#}"
if [[ "$last" == *'IFS= read -r key'* ]]; then
    HOME="$TEST_REMOTE" bash -c "$last"
fi
MOCK
chmod +x "$TEMP_ROOT/bin/ssh"
export PATH="$TEMP_ROOT/bin:$PATH"
cd "$TEMP_ROOT"
bash "$ROOT/sshkey_builder.sh" example.com tester > first.log
key="$HOME/.ssh/example.com"
fingerprint=$(ssh-keygen -lf "$key")
[[ -s "$key" && -s "$key.pub" ]]
grep -q '^existing-key-without-newline$' "$TEST_REMOTE/.ssh/authorized_keys"
cp "$TEST_REMOTE/.ssh/authorized_keys" before
rm "$key.pub"
bash "$ROOT/sshkey_builder.sh" example.com tester > second.log
[[ "$fingerprint" == "$(ssh-keygen -lf "$key")" ]]
cmp before "$TEST_REMOTE/.ssh/authorized_keys"
printf 'restrict %s old-comment\n' "$(cat "$key.pub")" > "$TEST_REMOTE/.ssh/authorized_keys"
cp "$TEST_REMOTE/.ssh/authorized_keys" before
printf 'stale public key\n' > "$key.pub"
bash "$ROOT/sshkey_builder.sh" example.com tester > third.log
cmp before "$TEST_REMOTE/.ssh/authorized_keys"
: > "$TEST_LOG"
if TEST_VERIFY_EXIT=7 bash "$ROOT/sshkey_builder.sh" example.com tester > failed.log; then
    echo "Expected verification failure" >&2
    exit 1
fi
# Each recorded invocation has multiline arguments. Count the identity option.
[[ $(grep -c '^-i ' "$TEST_LOG") -eq 2 ]]
: > "$TEST_LOG"
if bash "$ROOT/sshkey_builder.sh" '-oProxyCommand=bad' tester 2>/dev/null; then exit 1; fi
if bash "$ROOT/sshkey_builder.sh" example.com '../bad' 2>/dev/null; then exit 1; fi
[[ ! -s "$TEST_LOG" ]]
printf 'example.com\ntester\n' | bash "$ROOT/sshkey_builder.sh" > interactive.log
echo "All local regression checks passed."
