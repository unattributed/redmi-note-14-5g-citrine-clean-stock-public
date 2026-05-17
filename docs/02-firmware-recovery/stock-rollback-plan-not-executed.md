# Stock Rollback Plan, Not Executed

## Current status

This document is a rollback planning artifact only.

No bootloader unlock, flashing, userdata erase, Xiaomi flash script execution, DSU installation, or relock operation is approved by this document.

## Purpose

Define the recovery evidence and decision boundary required before any destructive custom ROM, GSI, or bootloader unlock work proceeds on the Redmi Note 14 5G `citrine` device.

## Known recovery assets

The project has already recorded the following recovery prerequisites:

- Stock fastboot firmware package was acquired locally.
- Stock firmware SHA256 was recorded.
- Pre-unlock ADB readiness was confirmed.
- Pre-unlock fastboot readiness was confirmed.
- Bootloader state was confirmed as locked before unlock planning.
- Verified boot state was confirmed as green before unlock planning.
- AVB device state was confirmed as locked before unlock planning.
- Anti-rollback value reported by fastboot was recorded as `1`.

## Recovery assumptions

Rollback planning assumes the following remain true before any future destructive action:

- The official stock fastboot firmware package remains available locally.
- The locally stored stock firmware hash still matches the recorded hash.
- The device can enter fastboot mode.
- The project has a current backup and account recovery plan.
- The operator accepts the possibility of data wipe and failed boot.

## Required pre-rollback checks

Before any rollback command is ever executed, complete and record:

- Recalculate the stock fastboot ROM SHA256.
- Compare recalculated SHA256 with the repository-recorded value.
- Confirm exact device codename and product state.
- Confirm current slot state.
- Confirm anti-rollback value.
- Confirm the intended rollback package is for the same device family and region.
- Confirm the selected rollback method is official or fully understood.
- Confirm the device will not be relocked after modified images have been used.

## Explicitly blocked actions

The following remain blocked until a later decision record explicitly approves them:

- `fastboot flashing unlock`
- `fastboot oem unlock`
- Xiaomi `flash_all*.sh` execution
- Manual partition flashing
- GSI flashing
- DSU installation
- Bootloader relock
- Userdata wipe

## Relock warning

Do not relock the bootloader after modified images, non-stock images, GSI images, or uncertain firmware state. Relocking in a modified or mismatched state can create a brick risk.

## Current conclusion

Rollback planning is documented, but rollback is not approved and has not been executed.

This document supports bootloader unlock planning only. It does not approve unlock, flashing, rollback execution, or relock.


## Step 20 dry-run readiness result

Evidence bundle:

```text
citrine-stock-rollback-dryrun-readiness-20260517-142604.tar.gz
```

Result: rollback readiness is stronger, but still partial.

This confirms that the stock fastboot firmware tree, important image files, script anatomy, and current fastboot state can be inspected safely. It does not prove a successful reflash.

Rollback execution remains not approved.
