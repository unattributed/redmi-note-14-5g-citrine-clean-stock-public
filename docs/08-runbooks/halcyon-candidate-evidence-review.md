# Halcyon Candidate Evidence Review Runbook

This runbook is research only. It does not install Halcyon or modify the phone.

## Allowed

- Review the Halcyon device page.
- Review release metadata.
- Look for checksums or release integrity methods.
- Look for public bug reports.
- Look for public maintainer notes.
- Record non-secret findings.

## Not allowed

- Bootloader unlock.
- Flashing `vendor_boot`.
- Booting custom recovery.
- Formatting data.
- ADB sideload.
- Installing DSU or GSI images.
- Sideloading Google applications.
- Relocking the bootloader.

## Evidence to collect

- Exact build package name.
- Release date.
- Maintainer identity as publicly listed.
- Required firmware base.
- Integrity information.
- Known bugs.
- Functional phone reports.
- Google Play and Play Protect behavior reports.
- Play Integrity behavior reports.
- Rollback notes.

## Output

Update:

```text
docs/12-functional-phone-feasibility/halcyon-beryl-candidate-review-2026-05-17.md
```

No candidate review alone approves bootloader unlock or flashing.
