# Decisions

This directory records project decisions for the Redmi Note 14 5G `citrine` work.

## Active decision

- `0009-clean-stock-daily-driver-path.md`

The current active path is the clean-stock HyperOS daily-driver strategy.

## Historical or superseded decisions

- `0001-recovery-first-gsi-first.md`, superseded by the clean-stock HyperOS track.

## Current project boundary

The current proven path keeps the phone on stock HyperOS with the bootloader locked.

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, or system image modification is part of the current active path.

## Current cleanup boundary

Clean Stock Milestone 1 is complete.

Broad package cleanup is stopped. Further package changes require a specific observed behavior tied to a specific package.
