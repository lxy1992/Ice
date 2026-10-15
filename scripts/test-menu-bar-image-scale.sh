#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE_CACHE="${TMPDIR:-/tmp}/ice-menu-bar-image-scale-module-cache"
BINARY="${TMPDIR:-/tmp}/ice-menu-bar-image-scale-tests"

mkdir -p "$MODULE_CACHE"
xcrun swiftc \
    -module-cache-path "$MODULE_CACHE" \
    "$ROOT/Ice/Utilities/MenuBarImageScaleResolver.swift" \
    "$ROOT/scripts/test-menu-bar-image-scale.swift" \
    -o "$BINARY"
"$BINARY"
