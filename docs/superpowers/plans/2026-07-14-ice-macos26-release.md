# Ice macOS 26 Fork Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Publish app version `0.11.13` build `1122` under tag `0.11.13-macos26.1` as a universal, independently identified, Developer ID signed and notarized GitHub prerelease from `lxy1992/Ice`.

**Architecture:** Keep the verified macOS 26 application code unchanged. Add a small distribution policy that prevents Sparkle initialization for this fork, replace upstream identity/repository metadata, and add a shell validator that makes release invariants executable. Use an isolated release worktree and a staged build-sign-notarize-publish pipeline with verification at every boundary.

**Tech Stack:** Swift 5, SwiftUI/AppKit, Xcode/xcodebuild, Sparkle (linked but disabled for this distribution), codesign, notarytool/Xcode notarization, ditto, shasum, Git, GitHub CLI.

**Global Constraints:** Never expose certificate private keys or notarization credentials. Do not publish an artifact unless the universal architectures, nested signatures, hardened runtime, notarization ticket, ZIP hash, and extracted app all verify. Do not reuse upstream bundle IDs or updater trust material.

---

### Task 1: Add an executable release configuration contract

**Files:**
- Create: `scripts/validate-release-configuration.sh`

1. Write checks for version/build, both bundle IDs, signing team, XPC service name, fork repository links, and absence of upstream Sparkle feed/key.
2. Run the validator before changing production metadata and record the expected failures (RED).
3. Keep the validator portable to the macOS system shell and make failure messages identify the broken invariant.

### Task 2: Apply independent release metadata

**Files:**
- Modify: `Ice.xcodeproj/project.pbxproj`
- Modify: `Shared/Services/MenuBarItemService.swift`
- Modify: `Ice/Resources/Info.plist`

1. Set standards-compliant marketing version `0.11.13` and build `1122` for the app and XPC in Debug and Release; keep `macos26.1` in the tag/release label only.
2. Set team `L9USTT7J86`, main ID `com.lxy1992.Ice`, and service ID `com.lxy1992.Ice.MenuBarItemService` in all configurations.
3. Change the hard-coded XPC Mach service name to the fork ID.
4. Remove the upstream `SUFeedURL` and `SUPublicEDKey` values.
5. Run the validator; metadata checks should pass while updater/UI checks remain RED.

### Task 3: Disable unowned update delivery and point support links to the fork

**Files:**
- Modify: `Ice/Main/Updates.swift`
- Modify: `Ice/MenuBar/ControlItem/ControlItem.swift`
- Modify: `Ice/Settings/SettingsPanes/AboutSettingsPane.swift`
- Modify: `README.md`

1. Add an `UpdatesManager.isEnabled` distribution switch declaring automatic updates unavailable.
2. Ensure `UpdatesManager` does not initialize Sparkle and every update entry point is guarded.
3. Hide the menu and About-pane update controls when updates are unavailable.
4. Point contribute/report/download links to `lxy1992/Ice`; label Homebrew as upstream-only; remove the fork's automatic-updates feature claim.
5. Run the validator and verify all checks pass (GREEN).

### Task 4: Verify source and unsigned products

**Files:** none

1. Run `git diff --check` and SwiftLint.
2. Build Debug unsigned for arm64.
3. Build Release unsigned as universal (`ARCHS='arm64 x86_64'`, `ONLY_ACTIVE_ARCH=NO`).
4. Inspect the built app/XPC plists and binaries for version, IDs, service name, and both architectures.
5. Run Xcode static analysis and any focused regression tests available in the project.

### Task 5: Review, commit, and push the release branch

**Files:** all changed files above

1. Review the complete diff specifically for updater/network and signing identity risks.
2. Confirm the branch is based on the fetched fork `main` merge commit.
3. Commit only scoped release files and push `codex/release-0.11.13-macos26.1`.
4. Open a Chinese pull request against fork `main` and merge only after checks pass.

### Task 6: Produce a Developer ID universal archive

**Files:** none (local keychain/archive output only)

1. With action-time user confirmation, create/select a Developer ID Application certificate for `L9USTT7J86`.
2. Archive the merged/tag-candidate commit with Release, universal architectures, automatic signing disabled or explicitly bound to the selected Developer ID identity.
3. Verify the app and XPC service signatures, team ID, entitlements, hardened runtime, timestamps, and architecture slices.

### Task 7: Notarize, staple, and package

**Files:** release artifacts outside the repository

1. Submit the signed archive/ZIP to Apple's notary service without writing credentials into commands, files, or logs.
2. Wait for `Accepted`; retrieve the rejection log if not accepted.
3. Staple and validate the notarization ticket on `Ice.app`.
4. Create `Ice.zip` with `ditto` and `Ice.zip.sha256` with `shasum -a 256`.
5. Extract into a clean directory and repeat identity, architecture, strict codesign, and staple checks.

### Task 8: Publish and verify the GitHub prerelease

**Files:** none

1. Tag the exact merged, notarized source commit as `0.11.13-macos26.1` and push the tag.
2. Create a Chinese GitHub prerelease with compatibility scope, new-permission explanation, validation summary, and both assets.
3. Download both published assets into a fresh directory.
4. Verify SHA-256, universal slices, nested Developer ID signatures, notarization staple, and first launch from `/Applications`.
5. Record the release URL and final verification evidence.
