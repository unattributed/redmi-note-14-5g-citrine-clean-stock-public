# Clean Stock Daily-Driver Validation Plan, 2026-05-17

## Current status

The phone is now a clean-stock daily-driver candidate.

The project should pause further package changes unless a specific user-visible issue appears.

## Current device state

    stock HyperOS retained
    bootloader locked
    no flashing
    no downgrade
    no userdata erase
    no DSU installation
    no Google application sideloading
    no Xiaomi flash script execution
    no relock
    no system image modification

## Current clean-stock result

Optional user-facing OEM launcher applications were removed or disabled for Android user 0.

Security Center remains intentionally retained.

MIUI Home remains the launcher for stability.

Google-oriented defaults are in place for dialer, SMS, browser, and assistant role holder where supported.

## Daily-driver validation items

Use the phone normally and watch for:

    phone calls
    SMS and RCS behavior
    mobile data
    Wi-Fi
    Bluetooth
    camera
    gallery/photo viewing through Google Photos or chosen replacement
    Play Store updates
    notifications
    banking applications
    authenticator applications
    password manager
    Signal
    WhatsApp
    LINE
    Google account sync
    Proton account applications
    battery behavior
    lock screen and unlock behavior
    app permissions
    unexpected Xiaomi/OEM notifications
    advertisements
    launcher suggestions
    app suggestions
    crashes or repeated dialogs

## Issue log format

When a problem appears, record:

    date/time:
    symptom:
    visible app or notification:
    package suspected:
    command or screenshot used to confirm:
    restore command attempted:
    result:

## Stop condition

Do not remove, disable, or change additional packages unless a specific behavior is observed and tied to a specific package.

## Restore reference

Use the committed restore script if Milestone 1 needs to be reverted:

    scripts/restore-clean-stock-milestone1-user0.sh --dry-run
    scripts/restore-clean-stock-milestone1-user0.sh --execute
