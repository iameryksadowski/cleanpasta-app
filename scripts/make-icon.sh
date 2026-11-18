#!/bin/sh
# design/icon.svg -> Resources/AppIcon.icns (light, the default) and design/icon-dark.svg -> Resources/AppIcon-dark.png (needs rsvg-convert: brew install librsvg).
set -eu
cd "$(dirname "$0")/.."
SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"
for size in 16 32 128 256 512; do
  rsvg-convert -w $size -h $size design/icon.svg -o "$SET/icon_${size}x${size}.png"
  rsvg-convert -w $((size * 2)) -h $((size * 2)) design/icon.svg -o "$SET/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rsvg-convert -w 1024 -h 1024 design/icon.svg -o design/icon-1024.png
# dark variant: the app shows it in the Dock while macOS is in dark mode
rsvg-convert -w 512 -h 512 design/icon-dark.svg -o Resources/AppIcon-dark.png
# menu bar: the clipboard of the icon as a template image (18 pt)
rsvg-convert -w 18 -h 18 design/menubar.svg -o Resources/MenuBarIcon.png
rsvg-convert -w 36 -h 36 design/menubar.svg -o Resources/MenuBarIcon@2x.png
echo "Resources/AppIcon.icns, Resources/AppIcon-dark.png, Resources/MenuBarIcon*.png"
