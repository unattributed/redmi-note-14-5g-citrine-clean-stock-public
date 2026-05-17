# Project Index

This private repository tracks the Redmi Note 14 5G `citrine` ROM development and clean-stock engineering effort.

## Goals

- Preserve stock recovery capability before any destructive action.
- Document the stock firmware, partition layout, boot chain, and AVB model.
- Evaluate Treble, DSU, GSI, and custom ROM feasibility before any bootloader unlock decision.
- Maintain a reviewable decision history for factory rollback, custom ROM feasibility, and clean-stock operation.
- Preserve a safe daily-driver phone state.

## Current phase

Clean-stock Milestone 1 is complete and under daily-driver validation.

The current device path is not custom ROM flashing. The current path is stock HyperOS with Android user 0 package cleanup, Google-oriented defaults, MIUI Home retained for stability, and a restore script committed.

## Current non-goals

- No bootloader unlock.
- No flashing.
- No downgrade.
- No userdata erase.
- No DSU installation.
- No Google application sideloading.
- No Xiaomi flash script execution.
- No relock.
- No broad package cleanup unless a specific observed issue is tied to a package.
- No committing multi-GB firmware, extracted images, private evidence, or device identifiers.

## Current clean-stock result

- Optional OEM launcher-visible applications were removed or disabled for Android user 0.
- `com.miui.securitycenter` is intentionally retained.
- Google Phone, Google Messages, and Chrome are validated as default handlers for tested intents.
- Google app is the assistant role holder, with device-specific ASSIST intent behavior noted.
- MIUI Home remains the launcher.
- The phone survived a reboot and normal phone functions were confirmed working.

## Repository sections

| Path | Purpose |
| --- | --- |
| `docs/01-device-profile/` | Device identity, hardware, and live property summaries |
| `docs/02-firmware-recovery/` | Stock firmware acquisition and recovery planning |
| `docs/03-partition-analysis/` | Dynamic partition and EROFS analysis |
| `docs/04-bootchain-avb/` | Boot image, vendor boot, DTBO, and AVB notes |
| `docs/05-gsi-readiness/` | Treble, DSU, GSI, and fastboot readiness |
| `docs/06-kernel-source/` | Xiaomi kernel source branch notes |
| `docs/07-decisions/` | Engineering decision records |
| `docs/08-runbooks/` | Repeatable procedures |
| `docs/09-evidence-index/` | Evidence bundle index and manifest |
| `docs/10-risk-register/` | Active project risks |
| `docs/12-functional-phone-feasibility/` | Custom ROM and functional phone feasibility evidence |
| `docs/13-clean-stock-feasibility/` | Clean-stock package cleanup and daily-driver validation |
| `docs/project-state/` | Current project state summaries |
| `maint/` | Maintenance scripts and helper tooling |
| `evidence/` | Small sanitized committed evidence bundles and manifests |
| `scripts/` | Read-only collectors, package cleanup helpers, and restore tooling |
