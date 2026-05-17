# Decision 0004, Bootloader Unlock Go/No-go Evidence Requirements

## Context

The DSU-first investigation phase is closed.

Decision 0003 concluded that DSU exists on the stock HyperOS build, but it is not safely exposed as a user-accessible test path. The device remains locked, secure, green, and enforcing. The project still has only one physical device.

The next phase is not bootloader unlock. The next phase is bootloader unlock go/no-go evidence collection.

## Source basis

Official Xiaomi support material states that unlocking the bootloader reduces device security, increases risk of data leakage, may affect warranty or service, and may cause data loss, boot failures, and compatibility issues with unsupported ROMs.

Official Xiaomi support material also states that for Xiaomi HyperOS, unlock access is limited to some users, only Xiaomi accounts registered outside Mainland China can apply for unlock privileges for non-Mainland China devices, unlock privileges are time-sensitive, up to three devices are supported per account, and Xiaomi Community is the official application path.

Xiaomi bootloader FAQ material also describes account and device binding through Developer Options, fastboot mode, use of the Xiaomi unlock tool, valid SIM expectations, and waiting for pairing where applicable.

## Decision

Do not unlock the bootloader yet.

Before any unlock attempt, the project must complete and commit a bootloader unlock go/no-go evidence package that answers every required item below.

## Required evidence before go/no-go

### Official procedure

- Official Xiaomi unlock procedure documented.
- Xiaomi Community unlock application path documented.
- Xiaomi account eligibility documented.
- Device region and account region compatibility documented.
- SIM requirement documented.
- Account and device binding requirement documented.
- Wait-period behavior documented.
- Device unlock limits documented.

### Data and account impact

- Data wipe impact accepted or rejected.
- Phone backup status documented.
- Photos, messages, authenticator apps, banking apps, SIM/eSIM, and local files reviewed.
- Xiaomi account access verified.
- Google account access verified.
- Two-factor recovery paths verified.

### Recovery readiness

- Stock fastboot ROM path documented.
- Stock fastboot ROM SHA256 documented.
- Firmware version match documented.
- Fastboot access reconfirmed.
- ADB access reconfirmed.
- Rollback command plan drafted but not executed.
- Xiaomi flash scripts reviewed but not executed.
- Anti-rollback state reviewed.

### First test target

- First post-unlock action defined.
- First post-unlock action must be minimal and reversible.
- First test target documented with exact artifact name and checksum.
- No GSI or ROM flash target may be used without an additional go/no-go record.

### First rollback target

- First rollback path defined.
- Expected fastboot command sequence documented but not executed.
- Expected post-rollback validation documented.
- Expected AVB and lock-state validation documented.

## Go/no-go gates

The unlock phase is blocked unless all gates are true:

- The user accepts data wipe risk.
- The user accepts warranty and support risk.
- The user accepts security risk.
- The official Xiaomi unlock procedure is understood.
- The account and device binding path is understood.
- Stock firmware rollback readiness is documented.
- The first post-unlock test target is defined.
- The first rollback target is defined.
- A separate final unlock decision record is written and committed.

## Current status

Go/no-go status: no-go.

The project is approved only for research, documentation, backups, read-only device checks, and rollback planning.

## Explicitly not approved

- Bootloader unlock.
- `fastboot flashing unlock`.
- `fastboot oem unlock`.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh` scripts.
- DSU installation.
- GSI installation.
- Relocking the bootloader after modified images.

## Reversal plan

If the unlock path is judged too risky, the project remains in locked-bootloader research mode. The stock firmware, kernel source, partition analysis, AVB evidence, and DSU evidence remain useful for future planning without modifying the phone.
