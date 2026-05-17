# Decision 0003, DSU Present but Not Safely Exposed on Stock HyperOS

## Context

The Redmi Note 14 5G `citrine` device completed the DSU-first investigation phase.

Evidence collected so far confirms:

- ADB authorization works.
- Fastboot access works.
- The device is Treble-enabled.
- Dynamic partitions are enabled.
- Virtual A/B and Virtual A/B compression are enabled.
- `/data` is F2FS.
- The device is locked, secure, green, and enforcing.
- `com.android.dynsystem` is installed as a privileged system app.
- `/system/bin/gsi_tool` exists.
- `gsi_tool status` returned `normal`.
- `gsid` and DSU-related services were present during inspection.
- `DSU Loader` or `Dynamic System Updates` was not visible in Developer Options.
- Official Android SDK tooling decoded `DynamicSystemInstallationService.apk`.

The official APK decode confirmed:

- `.DynamicSystemInstallationService` is exported.
- `.DynamicSystemInstallationService` is protected by `android.permission.INSTALL_DYNAMIC_SYSTEM`.
- `.VerificationActivity` is exported.
- `.VerificationActivity` is protected by `android.permission.INSTALL_DYNAMIC_SYSTEM`.
- `.VerificationActivity` declares `android.os.image.action.START_INSTALL`.
- `.VerificationActivity` declares `android.intent.category.DEFAULT`.
- `.VerificationActivity` declares `content`, `file`, `http`, and `https` data schemes.

## Decision

Treat DSU as present but not safely exposed on the stock HyperOS build.

Do not attempt DSU installation from shell, direct activity launch, `gsi_tool install`, or hidden intent paths without a separate go/no-go decision record.

Move the project from DSU-first investigation into bootloader unlock go/no-go planning.

This is not approval to unlock the bootloader.

## Rationale

The platform has the DSU backend and the DSU APK manifest contains an exported verification activity. However, the activity is permission-gated by `android.permission.INSTALL_DYNAMIC_SYSTEM`, the normal Developer Options UI entry was not visible, and shell resolver checks did not establish a safe user-accessible installation path.

A direct attempt to start hidden DSU flows or pass image URLs would no longer be evidence collection. It would be an installation attempt and should require a separate approval record.

## Consequences

The DSU-first investigation phase is closed.

Future work should focus on:

1. confirming the official Xiaomi bootloader unlock process,
2. documenting account, wait-period, region, and wipe implications,
3. confirming stock firmware rollback readiness,
4. preparing a bootloader unlock go/no-go decision record,
5. identifying the first reversible test target after unlock.

## Reversal plan

This decision can be reversed only if a later evidence record confirms a safe, visible, user-controlled DSU Loader path on this stock build.

A reversal record must document:

- the exact UI path,
- screenshots or sanitized notes,
- the exact image source,
- the installation prompts shown,
- the abort or rollback behavior,
- and confirmation that no hidden privileged bypass was required.

## Current rule

No DSU installation.
No hidden activity launch.
No `gsi_tool install`.
No `gsi_tool enable`.
No bootloader unlock.
No flashing.
No Xiaomi `flash_all*.sh` execution.
