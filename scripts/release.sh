#!/bin/sh
# Release the version at the top of CHANGELOG.md: build, sign the update (EdDSA), write
# appcast.xml with the changelog, upload the zip and the appcast to Cloudflare R2 (served by the
# Worker in services/updates, like Mowa), then publish a GitHub release with the zip, the DMG,
# appcast.xml and install.sh. Run by Eryk on main after merging development (docs/dystrybucja.md).
set -eu
cd "$(dirname "$0")/.."
REPO="iameryksadowski/cleanpasta-app"
UPDATES="https://cleanpasta.eryksadowski.workers.dev/updates"
BUCKET="cleanpasta-releases"
WRANGLER="pnpm dlx wrangler@4.151.0"
# The update key (docs/dystrybucja.md): the private key must fit the public key built into every app.
KEY="${SPARKLE_PRIVATE_KEY_FILE:-$HOME/.config/eryksadowski/signing/cleanpasta-sparkle-private-key.txt}"
SPARKLE_PRIVATE_KEY_FILE="$KEY" ./scripts/make-update-key.sh --check
REQUIRE_SIGNING=1 ./scripts/build-app.sh
VERSION="$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' CHANGELOG.md | head -1)"
BUILD="$(git rev-list --count HEAD)"
ZIP="dist/Cleanpasta-$VERSION.zip"
BIN="$(find .build -type d -path '*artifacts/sparkle/Sparkle/bin' | head -1)"
SIGNATURE="$("$BIN/sign_update" --ed-key-file "$KEY" "$ZIP")"
# Check the signature independently of Sparkle's code, with the public key the apps carry.
TOOL="$(mktemp -d)"
trap 'rm -rf "$TOOL"' EXIT
xcrun swiftc -O scripts/ed25519-tool.swift -o "$TOOL/ed25519-tool" -module-cache-path "$TOOL/cache"
ED_SIGNATURE="$(printf '%s\n' "$SIGNATURE" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
"$TOOL/ed25519-tool" verify "$(tr -d '[:space:]' < Resources/sparkle-public-key.txt)" "$ED_SIGNATURE" "$ZIP" || { echo "The update signature does not verify" >&2; exit 1; }
# Changelog section of this version, as HTML for the update window (cleaned by our own CLI)
NOTES="$(awk -v v="$VERSION" '$0 ~ "^## \\[" v "\\]" {on=1; next} /^## \[/ {on=0} on' CHANGELOG.md)"
NOTES_HTML="$(printf '%s\n' "$NOTES" | "dist/Cleanpasta.app/Contents/Helpers/cleanpasta" --markdown --font-size 0 --keep-quotes --print html)"
cp "$ZIP" dist/Cleanpasta.zip
cat > dist/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Cleanpasta</title>
    <item>
      <title>Cleanpasta $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[$NOTES_HTML]]></description>
      <enclosure url="$UPDATES/$VERSION/Cleanpasta-$VERSION.zip" $SIGNATURE type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
# Cloudflare first: the zip before the appcast, so the appcast never points at a missing file.
put() { (cd services/updates && $WRANGLER r2 object put "$BUCKET/$1" --file "../../$2" --content-type "$3" --remote); }
put "updates/$VERSION/Cleanpasta-$VERSION.zip" "$ZIP" application/zip
put updates/appcast.xml dist/appcast.xml "application/xml; charset=utf-8"
curl -fsS "$UPDATES/appcast.xml" | grep -q "<sparkle:shortVersionString>$VERSION<" || { echo "The appcast on $UPDATES does not show $VERSION" >&2; exit 1; }
[ "$(curl -fsSI "$UPDATES/$VERSION/Cleanpasta-$VERSION.zip" | tr -d '\r' | awk 'tolower($1) == "content-length:" {print $2}')" = "$(stat -f %z "$ZIP")" ] || { echo "The zip on $UPDATES has the wrong size" >&2; exit 1; }
# GitHub too: versions up to 1.1.0 read their appcast from the latest GitHub release.
cp scripts/install.sh dist/install.sh
printf '%s\n' "$NOTES" > dist/notes.md
gh release create "v$VERSION" --repo "$REPO" --target main --title "Cleanpasta $VERSION" --notes-file dist/notes.md \
  "$ZIP" "dist/Cleanpasta-$VERSION.dmg" dist/Cleanpasta.zip dist/appcast.xml dist/install.sh
echo "Released v$VERSION"
