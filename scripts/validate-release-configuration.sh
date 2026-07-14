#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Ice.xcodeproj/project.pbxproj"
INFO_PLIST="$ROOT/Ice/Resources/Info.plist"
SERVICE="$ROOT/Shared/Services/MenuBarItemService.swift"
UPDATES="$ROOT/Ice/Main/Updates.swift"
CONTROL_ITEM="$ROOT/Ice/MenuBar/ControlItem/ControlItem.swift"
ABOUT="$ROOT/Ice/Settings/SettingsPanes/AboutSettingsPane.swift"
README="$ROOT/README.md"

failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_literal() {
    local file="$1"
    local literal="$2"
    local description="$3"

    if grep -Fq -- "$literal" "$file"; then
        pass "$description"
    else
        fail "$description"
    fi
}

forbid_literal() {
    local file="$1"
    local literal="$2"
    local description="$3"

    if grep -Fq -- "$literal" "$file"; then
        fail "$description"
    else
        pass "$description"
    fi
}

require_count() {
    local file="$1"
    local literal="$2"
    local expected="$3"
    local description="$4"
    local actual

    actual="$( (grep -F -- "$literal" "$file" || true) | wc -l | tr -d ' ')"
    if [[ "$actual" == "$expected" ]]; then
        pass "$description"
    else
        fail "$description (expected $expected, found $actual)"
    fi
}

require_project_block_literal() {
    local configuration_id="$1"
    local literal="$2"
    local description="$3"
    local block

    block="$(awk -v configuration_id="$configuration_id" '
        !started && index($0, configuration_id " /*") {
            started = 1
        }
        started {
            print
        }
        started && $0 ~ /^[[:space:]]*};[[:space:]]*$/ {
            exit
        }
    ' "$PROJECT")"

    if [[ -n "$block" ]] && grep -Fq -- "$literal" <<< "$block"; then
        pass "$description"
    else
        fail "$description"
    fi
}

require_guard_after_signature() {
    local file="$1"
    local signature="$2"
    local description="$3"

    if awk -v signature="$signature" '
        index($0, signature) {
            found_signature = 1
            lines_remaining = 8
            next
        }
        found_signature && lines_remaining > 0 {
            if (index($0, "guard Self.isEnabled else {") > 0) {
                found_guard = 1
            }
            lines_remaining--
        }
        END {
            exit !(found_signature && found_guard)
        }
    ' "$file"; then
        pass "$description"
    else
        fail "$description"
    fi
}

require_count "$PROJECT" 'MARKETING_VERSION = ' 4 \
    'project declares marketing versions only for app/XPC Debug and Release'
require_count "$PROJECT" 'CURRENT_PROJECT_VERSION = ' 4 \
    'project declares build numbers only for app/XPC Debug and Release'
require_count "$PROJECT" 'PRODUCT_BUNDLE_IDENTIFIER = ' 4 \
    'project declares bundle IDs only for app/XPC Debug and Release'
require_count "$PROJECT" 'DEVELOPMENT_TEAM = ' 2 \
    'project declares signing team only in project Debug and Release'
require_count "$PROJECT" '"CODE_SIGN_IDENTITY[sdk=macosx*]" = ' 3 \
    'project has exactly one Debug and two Release signing identity overrides'
require_count "$PROJECT" 'ENABLE_HARDENED_RUNTIME = YES;' 4 \
    'hardened runtime is enabled for app/XPC Debug and Release'

require_count "$PROJECT" 'MARKETING_VERSION = 0.11.13;' 4 \
    'app and XPC marketing version is numeric 0.11.13 in Debug and Release'
require_count "$PROJECT" 'CURRENT_PROJECT_VERSION = 1122;' 4 \
    'app and XPC build number is 1122 in Debug and Release'
require_count "$PROJECT" 'PRODUCT_BUNDLE_IDENTIFIER = com.lxy1992.Ice;' 2 \
    'app bundle ID is independent in Debug and Release'
require_count "$PROJECT" 'PRODUCT_BUNDLE_IDENTIFIER = com.lxy1992.Ice.MenuBarItemService;' 2 \
    'XPC bundle ID is independent in Debug and Release'
require_count "$PROJECT" 'DEVELOPMENT_TEAM = L9USTT7J86;' 2 \
    'project signing team is the fork owner in Debug and Release'
require_count "$PROJECT" '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Developer ID Application";' 2 \
    'app and XPC Release configurations select Developer ID Application signing'
forbid_literal "$PROJECT" 'K2ATHQPJDP' \
    'upstream signing team is absent from project settings'
forbid_literal "$PROJECT" 'com.jordanbaird.Ice' \
    'upstream bundle IDs are absent from project settings'

require_project_block_literal '716683372A767E6B006ABF84' 'DEVELOPMENT_TEAM = L9USTT7J86;' \
    'project Debug configuration uses the fork signing team'
require_project_block_literal '716683382A767E6B006ABF84' 'DEVELOPMENT_TEAM = L9USTT7J86;' \
    'project Release configuration uses the fork signing team'
require_project_block_literal '7166833A2A767E6B006ABF84' '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development";' \
    'app Debug configuration uses Apple Development signing'
require_project_block_literal '7166833A2A767E6B006ABF84' 'PRODUCT_BUNDLE_IDENTIFIER = com.lxy1992.Ice;' \
    'app Debug configuration uses the independent bundle ID'
require_project_block_literal '7166833B2A767E6B006ABF84' '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Developer ID Application";' \
    'app Release configuration uses Developer ID signing'
require_project_block_literal '7166833B2A767E6B006ABF84' 'ENABLE_HARDENED_RUNTIME = YES;' \
    'app Release configuration enables hardened runtime'
require_project_block_literal '7188A68E2E27F9ED008F131D' 'PRODUCT_BUNDLE_IDENTIFIER = com.lxy1992.Ice.MenuBarItemService;' \
    'XPC Debug configuration uses the independent bundle ID'
require_project_block_literal '7188A68F2E27F9ED008F131D' '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Developer ID Application";' \
    'XPC Release configuration uses Developer ID signing'
require_project_block_literal '7188A68F2E27F9ED008F131D' 'ENABLE_HARDENED_RUNTIME = YES;' \
    'XPC Release configuration enables hardened runtime'

require_literal "$SERVICE" 'static let name = "com.lxy1992.Ice.MenuBarItemService"' \
    'XPC client uses the independent Mach service name'
forbid_literal "$SERVICE" 'com.jordanbaird.Ice.MenuBarItemService' \
    'upstream XPC Mach service name is absent'

forbid_literal "$INFO_PLIST" '<key>SUFeedURL</key>' \
    'unowned Sparkle feed URL is absent'
forbid_literal "$INFO_PLIST" '<key>SUPublicEDKey</key>' \
    'unowned Sparkle public key is absent'
forbid_literal "$INFO_PLIST" 'jordanbaird.github.io/ice-releases' \
    'upstream appcast host is absent'
if plutil -lint "$INFO_PLIST" >/dev/null; then
    pass 'source Info.plist is valid'
else
    fail 'source Info.plist is valid'
fi

require_literal "$UPDATES" 'static let isEnabled = false' \
    'fork distribution declares automatic updates disabled'
require_count "$UPDATES" 'guard Self.isEnabled else {' 6 \
    'all update manager initialization, settings, and entry points guard Sparkle'
require_guard_after_signature "$UPDATES" 'func performSetup(with appState: AppState)' \
    'update setup returns before initializing Sparkle when disabled'
require_guard_after_signature "$UPDATES" '@objc func checkForUpdates()' \
    'manual and notification update entry points return when disabled'
require_literal "$UPDATES" 'private lazy var updaterController' \
    'Sparkle controller is not exposed outside the update manager'
require_literal "$UPDATES" 'private var updater: SPUUpdater' \
    'Sparkle updater is private to the update manager'
require_literal "$CONTROL_ITEM" 'if UpdatesManager.isEnabled {' \
    'menu update entry point is hidden when updates are disabled'
require_literal "$ABOUT" 'if UpdatesManager.isEnabled {' \
    'About update controls are hidden when updates are disabled'

require_count "$README" 'https://github.com/lxy1992/Ice/releases/tag/0.11.13-macos26.1' 3 \
    'README download links target the published prerelease tag'
forbid_literal "$README" 'https://github.com/lxy1992/Ice/releases/latest' \
    'README does not use latest for a GitHub prerelease'
forbid_literal "$README" 'https://github.com/jordanbaird/Ice/releases' \
    'README has no upstream release download link'
require_literal "$README" 'upstream official build' \
    'README labels Homebrew as the upstream build'
forbid_literal "$README" '- [x] Automatic updates' \
    'README does not claim automatic updates for the fork'
require_literal "$README" 'https://img.shields.io/github/license/lxy1992/Ice' \
    'README license badge targets the fork'
require_literal "$ABOUT" 'URL(string: "https://github.com/lxy1992/Ice")!' \
    'About contribution and issue links target the fork'

if (( failures > 0 )); then
    printf '\nRelease configuration validation failed with %d issue(s).\n' "$failures" >&2
    exit 1
fi

printf '\nRelease configuration validation passed.\n'
