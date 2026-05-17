# Android ROM Development, Redmi Note 14 5G, citrine

This repository tracks the safe engineering workflow for the Redmi Note 14 5G `citrine` project.

The original long-term goal was to evaluate whether a clean Android, AOSP, or Lineage-style ROM path was feasible. The current proven daily-driver path is the **clean-stock HyperOS track**: keep the stock ROM, locked bootloader, modem, camera, Play services, and rollback posture intact, while removing or disabling unwanted OEM launcher-visible applications only for Android user 0.

## Target device

- Device: Redmi Note 14 5G
- Codename: `citrine`
- Xiaomi firmware naming observed: `beryl` / `beryl_dc`
- Platform: MediaTek MT6855
- Current stock OS observed: HyperOS 3.0, Android 16
- Current bootloader state: locked
- Current practical strategy: clean-stock daily-driver validation, no broad package changes

## Current project position

### Track 1, factory rollback

Factory rollback evidence is partially proven, but not end-to-end proven.

Proven or recorded:

- stock fastboot ROM evidence,
- checksum records,
- fastboot access,
- ADB access,
- anti-rollback value,
- flash script anatomy,
- image inventory,
- dry-run rollback readiness evidence.

Not proven:

- actual full reflash,
- hard-brick recovery,
- recovery if fastboot is unavailable,
- MediaTek authenticated service-tool recovery,
- safe relock after modification.

### Track 2, custom ROM

The custom ROM path is blocked.

AlphaDroid is the strongest reachable candidate lead, but release integrity and functional phone proof are not sufficient to justify bootloader unlock. Halcyon was investigated, but local source retrieval hit DNS or source retrieval issues.

The current decision remains: **do not unlock the bootloader for the custom ROM path**.

### Track 3, clean stock

The clean-stock path is the successful current path.

Current result:

- stock HyperOS retained,
- bootloader locked,
- no flashing,
- no downgrade,
- no userdata erase,
- no DSU installation,
- no Google application sideloading,
- no Xiaomi flash script execution,
- no relock,
- optional launcher-visible OEM applications removed or disabled for Android user 0,
- `com.miui.securitycenter` intentionally retained,
- Google Phone, Google Messages, Chrome, and Google assistant role holder validated where supported,
- MIUI Home retained for stability,
- post-reboot normal phone function validation completed,
- restore script committed.

## Current clean-stock stop condition

Do not remove, disable, or change additional packages unless a specific visible app, notification, advertisement path, service behavior, or privacy concern appears and can be tied to a specific package.

## Important scripts

```text
scripts/step43-adb-visible-launcher-inventory.sh
scripts/restore-clean-stock-milestone1-user0.sh
```

Use the inventory script for read-only state checks.

Use the restore script only if Milestone 1 needs to be reverted:

```text
scripts/restore-clean-stock-milestone1-user0.sh --dry-run
scripts/restore-clean-stock-milestone1-user0.sh --execute
```

## Safety model

This repository should not contain:

- stock firmware archives,
- extracted stock images,
- raw super images,
- phone serials, IMEI values, MAC addresses, SIM identifiers, or full getprop dumps,
- private evidence directories,
- Python virtual environments,
- AOSP, LineageOS, or kernel source checkouts.

Small sanitized shareable evidence bundles may be committed when they are explicitly created for repository traceability and do not contain sensitive device identifiers.

## Current rule

Do not flash, unlock, downgrade, erase userdata, relock, sideload Google applications, install DSU, or run Xiaomi flash scripts.

Do not continue broad package cleanup. Use the phone normally as a clean-stock daily-driver candidate and only make further changes after a specific issue is observed and tied to a package.
