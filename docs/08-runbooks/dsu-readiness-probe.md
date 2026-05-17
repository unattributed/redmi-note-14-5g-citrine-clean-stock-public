# DSU Readiness Probe Runbook

This runbook is for investigation only. It does not install, flash, unlock, or modify the phone.

## Purpose

Determine whether the stock Redmi Note 14 5G `citrine` user build exposes a usable Dynamic System Updates path.

## Safety boundary

Allowed:

- ADB read-only queries
- package and activity discovery
- settings discovery
- checking whether DSU components exist
- documenting results

Not allowed:

- bootloader unlock
- flashing
- `fastboot flash`
- Xiaomi `flash_all*.sh`
- DSU installation
- changing persistent feature flags without a separate decision record

## Evidence to collect later

A future script should collect:

- `adb shell pm list packages | grep -Ei 'dynsystem|gsi|dsu'`
- `adb shell cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL`
- `adb shell settings list global | grep -Ei 'dynamic|gsi|dsu'`
- `adb shell getprop | grep -Ei 'dynamic_system|gsi|dsu|virtual_ab|treble|vndk'`
- `adb shell ls -l /system/bin/gsi_tool /system/bin/gsid /apex/com.android.gsid*`
- Developer Options UI notes, if DSU Loader is visible

## Interpretation

If DSU components and launch paths are present, prepare a DSU-only test plan.

If DSU components are absent or blocked on this user build, prepare a bootloader unlock go/no-go decision record before any unlock.
