#!/bin/sh
# Cleanpasta's update key (Sparkle EdDSA), the same way as Mowa (docs/dystrybucja.md).
# The keychain is not touched. The public key is in Resources/sparkle-public-key.txt (committed,
# built into every app); the private key is a file in ~/.config/eryksadowski/signing and in 1Password.
#
#   scripts/make-update-key.sh           creates the key once; an existing key is never replaced
#   scripts/make-update-key.sh --check   says whether the private key fits the public key
#   SPARKLE_PRIVATE_KEY_FILE=FILE        another private key file
#
# Cleanpasta has had its key since 1.0.0, so creating one is refused: installed apps accept only
# updates signed with the key they carry.
set -eu
cd "$(dirname "$0")/.."

PRIVATE="${SPARKLE_PRIVATE_KEY_FILE:-$HOME/.config/eryksadowski/signing/cleanpasta-sparkle-private-key.txt}"
PUBLIC="Resources/sparkle-public-key.txt"
CHECK=0
case "${1:-}" in
  "") ;;
  --check) CHECK=1 ;;
  -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
xcrun swiftc -O scripts/ed25519-tool.swift -o "$WORK/ed25519-tool" -module-cache-path "$WORK/cache"
CURRENT="$(tr -d '[:space:]' < "$PUBLIC" 2>/dev/null || true)"

if [ "$CHECK" = 1 ]; then
  [ -n "$CURRENT" ] || { echo "No public key in $PUBLIC: builds would have no updates."; exit 1; }
  [ -f "$PRIVATE" ] || { echo "No private key at $PRIVATE (copy it from 1Password, the item with Cleanpasta's update key)."; exit 1; }
  [ "$("$WORK/ed25519-tool" public "$PRIVATE")" = "$CURRENT" ] || { echo "The private key $PRIVATE does not fit $PUBLIC."; exit 1; }
  echo "OK: the keys fit."
  exit 0
fi

if [ -n "$CURRENT" ]; then
  echo "$PUBLIC already holds a key. Nothing to do: a new key would cut installed apps off from updates." >&2
  exit 1
fi
[ ! -e "$PRIVATE" ] || { echo "$PRIVATE already exists. Nothing was changed." >&2; exit 1; }
mkdir -p "$(dirname "$PRIVATE")"
chmod 700 "$(dirname "$PRIVATE")"
mkdir "$WORK/keys"
"$WORK/ed25519-tool" keygen "$WORK/keys"
ditto "$WORK/keys/private.key" "$PRIVATE"
chmod 600 "$PRIVATE"
{ cat "$WORK/keys/public.key"; echo; } > "$PUBLIC"
echo "Public key:  $PUBLIC (commit it)"
echo "Private key: $PRIVATE (add it to 1Password right away)"
