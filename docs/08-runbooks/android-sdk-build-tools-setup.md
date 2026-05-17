# Android SDK Build Tools Setup Runbook

This runbook installs or verifies host-side Android SDK Build Tools so APK manifests can be decoded with official tooling.

## Purpose

Step 16 confirmed that `aapt2`, `aapt`, and `apkanalyzer` were missing on the Parrot workstation. These tools are needed to decode `DynamicSystemInstallationService.apk` more reliably than the self-contained parser used earlier.

## Safety boundary

Allowed:

- Host-side Android SDK tool detection.
- Host-side Android SDK Build Tools installation through `sdkmanager`, when available.
- Local APK manifest decoding.

Not allowed:

- DSU installation.
- Starting DSU activities.
- Passing image URLs.
- Bootloader unlock.
- Flashing.
- Persistent phone setting changes.

## Tooling target

Target packages:

```text
build-tools;36.0.0
platforms;android-36
```

The target matches the observed Android SDK level from the live device evidence.

## Procedure

Run:

```bash
bash scripts/step17-android-sdk-build-tools-setup.sh
```

If the script finds `sdkmanager`, it attempts to install the target build tools and platform package under the detected or default Android SDK root.

If `sdkmanager` is missing, install Android SDK Command-Line Tools from Google's official Android Studio download page, arrange them under an SDK root such as:

```text
/home/foo/Android/Sdk/cmdline-tools/latest
```

then rerun the setup script.

## Follow-up

After `aapt2`, `aapt`, or `apkanalyzer` is available, rerun:

```bash
bash scripts/step16-dynsystem-apk-official-tool-decode.sh
```
