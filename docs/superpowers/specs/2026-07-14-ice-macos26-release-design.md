# Ice macOS 26 Fork Release Design

## Context

The fork's `main` branch contains the complete macOS 26 compatibility base and the stability fixes verified on this Mac. The fork does not yet have a release pipeline, and the current project still carries the upstream bundle identifiers, signing team, Sparkle feed, download links, and a development-only version number.

## Goal

Publish a safe, independently identified, broadly installable prerelease from `lxy1992/Ice`:

- app/XPC marketing version: `0.11.13`
- release tag/channel label: `0.11.13-macos26.1`
- build: `1122`
- architectures: `arm64` and `x86_64`
- main bundle ID: `com.lxy1992.Ice`
- XPC bundle/service ID: `com.lxy1992.Ice.MenuBarItemService`
- signing team: `L9USTT7J86`
- distribution: Developer ID signed, Apple-notarized, stapled ZIP
- GitHub visibility: prerelease until broader compatibility feedback is collected

## Safety Boundaries

### Standards-compliant bundle version

`CFBundleShortVersionString` remains the three-component numeric value `0.11.13`, as required by Apple's bundle metadata contract. The `macos26.1` suffix is carried by the Git tag and GitHub release name rather than being embedded in `CFBundleShortVersionString`.

### Independent application identity

The fork must not ship with the upstream bundle IDs. Independent IDs prevent the fork from sharing TCC identity, launch-at-login state, updater state, and XPC registration with the upstream app. Existing upstream installations may therefore coexist, but users migrating to this fork must grant permissions once for the new identity.

### No upstream auto-update trust

The fork does not own the upstream Sparkle signing key or appcast. This release removes the upstream appcast URL and public key, does not start the Sparkle updater, and hides update controls. Users obtain later fork builds from the fork's GitHub Releases page until the fork owns an independently signed update feed.

### Minimal release-only changes

The release change is limited to identifiers, version/signing metadata, updater disablement, user-facing repository/install links, release validation, and release documentation. It does not modify the already-tested macOS 26 compatibility implementation.

## Packaging Flow

1. Validate source release metadata and absence of upstream updater configuration.
2. Build and analyze unsigned Debug/Release configurations.
3. Create or select a `Developer ID Application` certificate for team `L9USTT7J86`.
4. Archive a universal Release app with hardened runtime enabled.
5. Verify both the app and embedded XPC service are signed by the same Developer ID team.
6. Submit the archive to Apple's notary service, wait for acceptance, and staple the ticket to the app.
7. Package `Ice.app` as `Ice.zip`, generate `Ice.zip.sha256`, and verify the ZIP after extraction.
8. Merge the release commit, tag the exact commit, and publish a GitHub prerelease with both assets.
9. Download the published assets afresh and repeat architecture, signature, notarization, hash, and launch checks.

## User-Facing Changes

- README download links target `https://github.com/lxy1992/Ice/releases`.
- Homebrew is explicitly labeled as the upstream official build, not this fork.
- The About pane's contribution and issue links target the fork.
- Automatic update claims are removed for this fork release.

## Rollback

If signing, notarization, or post-publication verification fails, do not publish a final release. Delete or leave the GitHub release as a draft/prerelease, fix the release branch, increment the build number if a new notarization artifact is generated, and tag only a verified commit.
