# Android SDK Build Tools for APK Decode

This runbook prepares the workstation for authoritative APK manifest decoding.

## Purpose

The DSU APK was pulled safely from read-only `/system`, but the Parrot OS host did not have `aapt2`, `aapt`, or `apkanalyzer` available. A future run should install official Android SDK tooling and rerun the APK decode.

## Preferred tools

- `aapt2`, from Android SDK Build Tools.
- `apkanalyzer`, from Android SDK Command-Line Tools.

## Safety boundary

Allowed:

- Installing SDK tools on the Parrot OS workstation.
- Decoding a local APK copy.
- Reading APK manifest, permissions, components, and intent filters.

Not allowed:

- DSU installation.
- Starting DSU activities.
- Passing image URLs.
- Bootloader unlock.
- Flashing.
- Persistent phone setting changes.

## Next implementation note

A future setup script should locate an existing Android SDK first, then use `sdkmanager` to install build tools if available. If `sdkmanager` is unavailable, the script should stop and document what is missing instead of guessing a download URL.
