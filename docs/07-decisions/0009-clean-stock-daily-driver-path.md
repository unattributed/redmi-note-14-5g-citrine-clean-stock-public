# Decision 0009, Clean-Stock Daily-Driver Path

## Status

Accepted.

## Decision

Use the clean-stock HyperOS path as the current proven daily-driver strategy for the Redmi Note 14 5G `citrine`.

## Rationale

The clean-stock path achieved the project goal more safely than custom ROM, GSI, or flashing-based approaches at this stage.

It keeps the real-phone foundation intact while reducing unwanted OEM launcher-visible applications for Android user 0.

## Preserved device boundary

The project retains:

    stock HyperOS
    locked bootloader
    stock modem
    stock camera stack
    Play Store
    Play services
    Play Protect behavior
    rollback posture
    MIUI Home launcher for stability
    Security Center intentionally retained

## Explicit non-actions

This path does not perform:

    bootloader unlock
    flashing
    downgrade
    userdata erase
    DSU installation
    Google application sideloading
    Xiaomi flash script execution
    relock
    system image modification

## Current result

Clean Stock Milestone 1 is complete.

Optional user-facing OEM launcher applications were removed or disabled for Android user 0.

Google-oriented defaults were validated for dialer, SMS, browser, and assistant role holder where supported.

The phone survived reboot and normal phone functions worked.

A restore script exists:

    scripts/restore-clean-stock-milestone1-user0.sh --dry-run
    scripts/restore-clean-stock-milestone1-user0.sh --execute

## Stop condition

Broad package cleanup is stopped.

Further package changes should only happen if a specific visible app, notification, advertisement path, service behavior, or privacy concern appears and can be tied to a specific package.

## Current conclusion

The clean-stock HyperOS track is the active project path.

Recovery-first, GSI-first, and custom ROM paths remain historical or blocked until stronger evidence justifies reopening them.
