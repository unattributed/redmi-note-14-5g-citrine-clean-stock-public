# Xiaomi Unlock Source Review Runbook

This runbook collects official-source unlock evidence. It does not unlock the phone.

## Purpose

Build a reviewable source record for the Xiaomi HyperOS bootloader unlock path before any destructive action is considered.

## Allowed

- Reading official Xiaomi support pages.
- Recording source URLs and short paraphrased findings.
- Checking Xiaomi Community availability.
- Checking the phone UI for Developer Options unlock status without binding if not ready.
- Recording whether account/device binding is available.

## Not allowed

- Running Xiaomi unlock tool.
- Binding the device to an account unless a separate decision approves that step.
- Unlocking the bootloader.
- Running `fastboot flashing unlock`.
- Running `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh` scripts.
- Erasing userdata.

## Source review checklist

- [ ] Review Xiaomi global bootloader safety page.
- [ ] Review Xiaomi HyperOS bootloader FAQ page for non-Mainland China devices.
- [ ] Review local-region Xiaomi support page.
- [ ] Record whether Xiaomi Community is required.
- [ ] Record account eligibility requirements.
- [ ] Record SIM requirement.
- [ ] Record wait-period behavior.
- [ ] Record device count or account limits.
- [ ] Record warranty or service risk language.
- [ ] Record data loss and boot failure risk language.

## Output

Update:

```text
/docs/02-firmware-recovery/bootloader-unlock-go-no-go-evidence.md
```

Do not proceed to unlock until a later decision record explicitly approves it.
