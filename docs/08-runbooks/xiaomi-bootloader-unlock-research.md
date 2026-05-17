# Xiaomi Bootloader Unlock Research Runbook

This runbook collects evidence for the bootloader unlock go/no-go decision. It does not unlock the phone.

## Purpose

Document the official Xiaomi unlock path, account requirements, device binding behavior, wait periods, data wipe impact, and rollback readiness before any destructive operation is considered.

## Allowed

- Reading official Xiaomi support pages.
- Reading Xiaomi Community unlock requirements.
- Taking notes about eligibility and wait periods.
- Checking Developer Options visually.
- Checking whether Device Unlock Status exists.
- Confirming ADB and fastboot with read-only commands.
- Confirming stock firmware artifact paths and checksums.
- Confirming local backups.

## Not allowed

- Pressing unlock in the Xiaomi unlock tool.
- Running `fastboot flashing unlock`.
- Running `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh` scripts.
- Erasing userdata.
- Relocking the bootloader.
- Starting DSU installation.

## Evidence checklist

### Official Xiaomi material

Record source URLs and notes for:

- Bootloader unlock risks.
- Xiaomi HyperOS unlock eligibility.
- Xiaomi Community application process.
- Account region requirements.
- Device region requirements.
- Account and device binding procedure.
- SIM requirement.
- Wait period behavior.
- Per-account device limits.

### Local device readiness

Record:

- Current Android version.
- Current HyperOS version.
- Current active slot.
- Current bootloader lock state.
- Current AVB state.
- Current anti-rollback value.
- Current fastboot product.
- Current stock firmware package and SHA256.

### Backup readiness

Record yes, no, or not applicable:

- Photos backed up.
- Downloads backed up.
- Messaging data backed up.
- Authenticator recovery verified.
- Banking app recovery verified.
- SIM or eSIM recovery understood.
- Xiaomi account recovery verified.
- Google account recovery verified.

### Rollback readiness

Record:

- Stock fastboot ROM local path.
- Stock fastboot ROM SHA256.
- Extracted firmware path.
- Flash scripts present.
- Flash scripts reviewed.
- Flash scripts not executed.
- Rollback validation plan.

## Output

Create a later evidence document under:

```text
/docs/02-firmware-recovery/bootloader-unlock-go-no-go-evidence.md
```

The final unlock decision must be a separate decision record. This runbook alone does not approve unlock.
