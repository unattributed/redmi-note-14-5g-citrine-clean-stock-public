# DSU Component Inspection Runbook

This runbook is for read-only investigation of Dynamic System Updates components on the stock Redmi Note 14 5G `citrine` build.

## Purpose

Determine whether DSU is only hidden from the public UI, permission-gated, OEM-disabled, or partially present.

## Allowed

- ADB authorization checks
- Package inventory
- `dumpsys package com.android.dynsystem`
- Intent resolution checks using `cmd package resolve-activity`
- Read-only file existence checks
- `gsi_tool --help`
- Service list inspection
- Settings and property reads

## Not allowed

- DSU installation
- `gsi_tool install`
- `gsi_tool enable`
- `gsi_tool wipe`
- Any `fastboot flash` command
- Bootloader unlock
- Persistent settings changes
- Xiaomi `flash_all*.sh`

## Evidence expected

The script should produce a bundle under:

```text
/home/foo/android-rom-dev-evidence
```

The bundle should answer:

- Is `com.android.dynsystem` installed?
- Which activities, services, receivers, and permissions are declared?
- Does the public DSU start intent resolve?
- Does `gsi_tool --help` reveal safe next commands?
- Is `gsid` present as an init service?
- Is the DSU path hidden, blocked, or only partially exposed?

## Interpretation

If a public activity or safe system UI path exists, prepare a DSU-only test plan.

If only backend components exist, prepare a decision record describing whether to continue with deeper DSU research or move to a bootloader unlock go/no-go review.
