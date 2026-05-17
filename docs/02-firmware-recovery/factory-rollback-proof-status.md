# Factory Rollback Proof Status

## Current status

Factory rollback status is stronger than before, but still partial.

The project has not executed a factory reflash. Therefore rollback is not end-to-end proven.

## Evidence bundle

```text
citrine-stock-rollback-dryrun-readiness-20260517-142604.tar.gz
```

## What step 20 proved

- The local stock fastboot firmware tree exists.
- The stock package and checksum records are present.
- The selected firmware tree is `beryl_dc_global_images_OS3.0.1.0.WOQMIDC_16.0`.
- The flash script anatomy can be inspected without executing any flash command.
- The flash scripts include product checks for both `beryl` and `citrine`.
- The scripts include anti-rollback checks.
- Required stock image files are present, including `boot.img`, `vendor_boot.img`, `init_boot.img`, `dtbo.img`, `vbmeta.img`, `vbmeta_system.img`, `vbmeta_vendor.img`, `super.img`, `md1img.img`, and `lk.img`.
- Current read-only fastboot access works.
- Current fastboot product is `citrine`.
- Current slot is `b`.
- Slot count is `2`.
- Bootloader unlocked state is `no`.
- Secure boot is `yes`.
- Anti-rollback value is `1`.
- Bootloader version is `beryl_2605929bd_202604030659`.
- Baseband version is `MOLY.NR15.R3.MP.V167.P70`.

## What step 20 did not prove

- Successful full factory reflash.
- Recovery from hard brick.
- Recovery if fastboot is unavailable.
- MediaTek authenticated service-tool recovery.
- Safe relock after any modification.
- Xiaomi flash script behavior on this exact device after unlock.

## Safety result

The step 20 collector did not unlock, flash, erase userdata, execute Xiaomi flash scripts, install DSU, install a GSI, sideload Google applications, or relock the bootloader.

## Decision impact

The project has a credible fastboot rollback foundation, but not an end-to-end proven rollback procedure.

Factory rollback remains a partial proof, not a completed proof.

Bootloader unlock remains no-go.
