# DynamicSystem APK Official Tool Decode Runbook

This runbook is for read-only APK inspection only.

## Purpose

Decode the installed `DynamicSystemInstallationService.apk` with official Android tooling where available, such as `aapt2`, `aapt`, or `apkanalyzer`.

## Allowed

- Pulling the installed DSU APK from read-only `/system`.
- Running local APK analysis tools.
- Capturing manifest, permission, activity, and string evidence.

## Not allowed

- Starting DSU activities.
- Installing DSU.
- Running `gsi_tool install`, `enable`, `wipe`, or `wipe-data`.
- Bootloader unlock.
- Flashing.
- Persistent settings changes.

## Interpretation

Prefer Android package-manager evidence and official Android tooling output over the earlier self-contained parser output if they disagree.
