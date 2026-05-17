# Halcyon Release Integrity Review Runbook

This runbook is research only. It does not install Halcyon or modify the phone.

## Allowed

- Review candidate release pages.
- Record non-secret release metadata.
- Record whether checksums or signatures exist.
- Record whether release notes and known bugs exist.
- Record whether required base firmware is documented.

## Not allowed

- Bootloader unlock.
- Flashing `vendor_boot`.
- Flashing recovery.
- Formatting data.
- ADB sideload.
- Installing DSU or GSI images.
- Sideloading Google applications.
- Relocking the bootloader.

## Evidence to collect

- Build artifact URL.
- Build filename.
- Build date.
- Build size.
- Release channel.
- Required base firmware.
- Release checksum.
- Recovery image checksum.
- `vendor_boot` checksum.
- Maintainer notes.
- Known bug list.
- Update cadence.

## Current output target

```text
docs/12-functional-phone-feasibility/halcyon-release-integrity-review-2026-05-17.md
```

## Current decision

No-go for bootloader unlock.
