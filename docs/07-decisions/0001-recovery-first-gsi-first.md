# Decision 0001, Recovery-first and GSI-first Development Path

## Status

Superseded.

## Original decision

Use a recovery-first and GSI-first development path.

## Original rationale

At the time this decision was created, the project was still evaluating whether a clean Android, AOSP, Lineage-style, or GSI-based path was feasible for the Redmi Note 14 5G `citrine` device.

The recovery-first and GSI-first approach was chosen as an early exploratory strategy because it offered a lower-effort way to study compatibility before attempting full device-tree bring-up.

## Superseding decision

This decision is superseded by the clean-stock HyperOS track.

The current proven path keeps:

    stock HyperOS
    locked bootloader
    stock modem
    stock camera stack
    Play Store
    Play services
    Play Protect behavior
    rollback posture

The current clean-stock strategy removes or disables only selected Android user 0 packages and avoids flashing, unlocking, downgrading, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, and system image modification.

## Current project position

Recovery-first and GSI-first work is no longer the active project path.

Custom ROM and GSI work remain blocked until stronger public device-specific evidence exists, including functional phone proof, integrity proof, rollback safety, and a clear bootloader-unlock risk decision.

## Current conclusion

Decision 0001 is retained as historical project context only.

It should not be used as the active implementation plan.
