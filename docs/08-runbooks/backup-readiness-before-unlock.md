# Backup Readiness Before Unlock Runbook

This runbook is for planning only. It does not unlock, flash, erase userdata, install DSU, or modify the phone.

## Purpose

Prepare a reliable backup and recovery baseline before any future bootloader unlock decision.

## Allowed

- Review backup requirements.
- Record non-secret backup readiness status.
- Confirm that important accounts can be recovered.
- Confirm that important data exists on another trusted device or storage location.

## Not allowed

- Bootloader unlock.
- `fastboot flashing unlock`.
- `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh`.
- Erasing userdata.
- DSU installation.

## Evidence to collect manually

- Backup date.
- Backup location category, without secrets or exact private paths if the repo may later become public.
- Account recovery confirmation status.
- Applications that cannot be restored safely.
- Explicit list of data the user accepts losing.

## Output

Update:

```text
/docs/02-firmware-recovery/backup-readiness-evidence.md
```

Do not proceed to unlock until a later decision record explicitly approves it.
