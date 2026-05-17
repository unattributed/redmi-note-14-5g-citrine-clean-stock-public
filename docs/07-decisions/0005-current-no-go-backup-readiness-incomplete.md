# Decision 0005, Current No-go Because Backup Readiness Is Incomplete

## Context

The project has completed the DSU-first investigation and moved into bootloader unlock go/no-go planning.

Decision 0003 concluded that DSU is present on the stock HyperOS build, but it is not safely exposed as a user-accessible test path.

Decision 0004 defined the evidence required before any bootloader unlock go/no-go decision.

The backup readiness evidence now confirms several important items are complete:

- Shared storage backup completed outside Git.
- Photos and videos backed up.
- Downloads backed up.
- Documents backed up.
- Important chat application recovery reviewed or backed up through supported flows.
- Google account credentials confirmed.
- Password manager access confirmed on another trusted device.
- Stock fastboot ROM path recorded.
- Stock fastboot ROM SHA256 recorded.
- ADB and fastboot access confirmed after the latest baseline.
- Stock rollback plan documented but not executed.
- Security reduction risk accepted.

However, backup readiness and risk acceptance are still incomplete.

## Current blockers

Bootloader unlock remains blocked because these items are incomplete:

- Two-factor authentication recovery without relying only on this phone.
- Local app-exported data, where applicable.
- Data wipe risk acceptance.
- Warranty or service impact acceptance.
- Single-device risk acceptance.
- Rollback uncertainty acceptance.

## Decision

Bootloader unlock remains **no-go**.

The project must not unlock the bootloader, flash partitions, erase userdata, install DSU, run Xiaomi flash scripts, or relock the bootloader while these blockers remain open.

## Reasoning

The project has only one physical device. The current evidence shows that stock recovery planning has improved, but the remaining backup and risk items are material.

Proceeding before two-factor recovery, app export decisions, data wipe acceptance, warranty or service impact acceptance, single-device risk acceptance, and rollback uncertainty acceptance are resolved would be an avoidable operational risk.

## Scope

This decision applies to the current bootloader unlock planning phase.

It does not prevent continued research, documentation, backup verification, Xiaomi source review, or read-only state collection.

## Allowed next actions

- Continue non-secret backup readiness documentation.
- Verify two-factor recovery without relying only on this phone.
- Decide whether local app-exported data is needed or not applicable.
- Decide whether data wipe risk is accepted.
- Decide whether warranty or service impact is accepted.
- Decide whether single-device risk is accepted.
- Decide whether rollback uncertainty is accepted.
- Update the bootloader unlock go/no-go evidence worksheet.

## Explicitly not allowed

- Bootloader unlock.
- `fastboot flashing unlock`.
- `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh` scripts.
- Erasing userdata.
- Starting DSU installation.
- Running `gsi_tool install`, `enable`, `wipe`, `wipe-data`, or `cancel`.
- Relocking the bootloader after any modified image is used.

## Reopen condition

A future decision record may reconsider unlock only after the remaining blockers are either completed, marked not applicable with a clear reason, or explicitly accepted as known risks.

## Current conclusion

No-go for bootloader unlock.
