#!/bin/sh
# Keyboard-only dashes and quotes, converter tests (unit + WebKit paste), then the CLI build
# and JavaScriptCore parity with the TypeScript converter.
set -eu
cd "$(dirname "$0")/.."
python3 scripts/check-text.py >/dev/null || python3 scripts/check-text.py
swift build --product cleanpasta >/dev/null
(cd converter && node --test "tests/**/*.test.ts")
exec node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --disable-warning=ExperimentalWarning --test tests/*.test.ts
