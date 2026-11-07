#!/bin/sh
# One-time setup on the release Mac (run it yourself, it changes your keychain):
# 1. "Eryk Sadowski Code Signing" - a free self-signed certificate. A stable signature keeps
#    the Accessibility permission across updates.
# 2. Sparkle EdDSA key (a file, created once) - installed apps accept only updates signed with it.
# Backups land in ~/.config/eryksadowski/signing; move them to 1Password right after.
set -eu
cd "$(dirname "$0")/.."
OUT="$HOME/.config/eryksadowski/signing"
mkdir -p "$OUT" && chmod 700 "$HOME/.config/eryksadowski" "$OUT"

if security find-certificate -c "Eryk Sadowski Code Signing" >/dev/null 2>&1; then
  echo "Certificate: already in the keychain"
else
  PASS="$(openssl rand -hex 16)"
  /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$OUT/eryk-sadowski-code-signing.key" -out "$OUT/eryk-sadowski-code-signing.crt" \
    -subj "/CN=Eryk Sadowski Code Signing/O=Eryk Sadowski" \
    -addext "basicConstraints=critical,CA:false" -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
  /usr/bin/openssl pkcs12 -export -name "Eryk Sadowski Code Signing" -inkey "$OUT/eryk-sadowski-code-signing.key" \
    -in "$OUT/eryk-sadowski-code-signing.crt" -out "$OUT/eryk-sadowski-code-signing.p12" -passout "pass:$PASS"
  printf '%s\n' "$PASS" > "$OUT/eryk-sadowski-code-signing.p12-password.txt"
  rm -f "$OUT/eryk-sadowski-code-signing.key"
  chmod 600 "$OUT"/*
  security import "$OUT/eryk-sadowski-code-signing.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P "$PASS" -T /usr/bin/codesign
  echo "Certificate: imported"
fi

# Sparkle EdDSA key as a file (no keychain): the private key signs updates, the public
# key ships in the app (Resources/sparkle-public-key.txt).
if [ ! -f "$OUT/sparkle-private-key.txt" ]; then
  /opt/homebrew/bin/openssl genpkey -algorithm ed25519 -out "$OUT/sparkle-ed25519.pem" 2>/dev/null || openssl genpkey -algorithm ed25519 -out "$OUT/sparkle-ed25519.pem"
  openssl pkey -in "$OUT/sparkle-ed25519.pem" -outform DER | tail -c 32 | base64 > "$OUT/sparkle-private-key.txt"
  chmod 600 "$OUT"/*
fi
openssl pkey -in "$OUT/sparkle-ed25519.pem" -pubout -outform DER | tail -c 32 | base64 > Resources/sparkle-public-key.txt
echo "Sparkle public key: $(cat Resources/sparkle-public-key.txt) (Resources/sparkle-public-key.txt, commit it)"
echo
echo "Now add to 1Password (item \"Cleanpasta signing\") and delete the local copies:"
ls -1 "$OUT"
