# Bootloader Unlock Go/No-go Planning Runbook

This runbook prepares the next decision phase. It does not unlock the phone.

## Purpose

Define the evidence needed before deciding whether to unlock the Redmi Note 14 5G `citrine` bootloader.

## Allowed

- Researching the official Xiaomi unlock procedure.
- Capturing non-sensitive notes about prerequisites.
- Confirming local backups.
- Confirming stock firmware rollback readiness.
- Confirming fastboot access.
- Confirming current bootloader state with read-only commands.

## Not allowed

- Unlocking the bootloader.
- Running `fastboot flashing unlock`.
- Running `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh`.
- Erasing userdata.
- Starting DSU installation.

## Evidence needed before unlock decision

- Official Xiaomi unlock procedure documented.
- Account and device binding requirements documented.
- Wait-period behavior documented, if applicable.
- Data wipe impact accepted or rejected.
- Stock fastboot ROM path and SHA256 recorded.
- Fastboot rollback command plan drafted but not executed.
- First post-unlock test target identified.
- First rollback test target identified.
- Decision record written and reviewed.

## Current status

The project is not approved for bootloader unlock. The next step is research and documentation only.
