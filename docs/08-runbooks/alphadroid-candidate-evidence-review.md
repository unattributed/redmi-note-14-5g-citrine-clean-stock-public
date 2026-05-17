# AlphaDroid Candidate Evidence Review Runbook

This runbook is research only. It does not install AlphaDroid or modify the phone.

## Allowed

- Review public AlphaDroid release metadata.
- Record non-secret release information.
- Look for exact artifact names.
- Look for checksums or signatures.
- Look for source changelog and device changelog.
- Look for known bug reports.
- Look for functional phone reports.
- Look for Google Play, Play Protect, and Play Integrity behavior reports.

## Not allowed

- Bootloader unlock.
- Downgrade.
- Flashing `vendor_boot`.
- Flashing any partition.
- Formatting data.
- ADB sideload.
- DSU installation.
- Google application sideloading.
- Xiaomi flash script execution.
- Relock.

## Evidence to collect

- Candidate source URL.
- Exact release artifact names.
- GApps artifact name, if present.
- Vanilla artifact name, if present.
- Vendor boot artifact name, if present.
- SHA256 or signature status.
- Required base firmware.
- HyperOS 3 warning details.
- Downgrade requirement details.
- Known bug list.
- Functional phone reports.
- Google trust behavior reports.
- Rollback implications.

## Blocking rule

If the candidate requires downgrade from HyperOS 3, the project must not proceed until rollback and downgrade risk are separately understood.

## Current conclusion

Research only. No unlock or flash approval.
