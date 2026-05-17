# Decision 0002, DSU-first Before Bootloader Unlock

## Context

The Redmi Note 14 5G `citrine` device has now produced corrected live readiness evidence.

Confirmed live properties include:

- ADB authorization works.
- Fastboot access works.
- Device product is `citrine`.
- Current slot is `_b`.
- Slot count is `2`.
- Bootloader is locked.
- Secure boot is enabled.
- Anti-rollback value reported by fastboot is `1`.
- Verified boot state is `green`.
- AVB device state is `locked`.
- Verity mode is `enforcing`.
- Treble is enabled.
- Dynamic partitions are enabled.
- Virtual A/B is enabled.
- Virtual A/B compression is enabled.
- CPU ABI is `arm64-v8a`.
- Maximum CPU page size property is `16384`.
- `/data` is mounted as F2FS.
- Stock firmware and AVB evidence are preserved in the private repository.

The project has only one physical device.

## Decision

Prefer a DSU-first investigation before any bootloader unlock or permanent flash operation.

The next technical step is not to flash a GSI. The next step is to determine whether this stock user build exposes a usable DSU path through Developer Options, `am start-activity`, `gsi_tool`, or related system components.

## Rationale

DSU is designed to try a system image without corrupting the currently installed system image. This makes it a lower-risk investigation path than bootloader unlock and direct flashing.

The live evidence suggests the device is a plausible DSU or GSI candidate because it has Treble, dynamic partitions, Virtual A/B, F2FS `/data`, AVB, and an arm64 ABI.

## Consequences

This decision delays bootloader unlock until the DSU path has been checked.

If DSU is available, DSU testing becomes the preferred first live GSI experiment.

If DSU is blocked, hidden, OEM-disabled, or unsuitable, the project must create a separate bootloader unlock go/no-go record before unlocking.

## Reversal plan

This decision can be reversed only by a later decision record that documents:

1. stock recovery readiness,
2. data wipe acceptance,
3. bootloader unlock process,
4. AVB and rollback implications,
5. exact first flash target,
6. exact stock rollback process.
