# Bootloader Unlock Go/No-go Evidence

## Current status

Bootloader unlock is not approved.

This document is an evidence worksheet for the next decision phase. It does not authorize unlocking, flashing, erasing userdata, running Xiaomi flash scripts, or starting DSU installation.

## Vendor source basis

Official Xiaomi support material reviewed during this phase states the following operational and risk themes:

- unlocking the bootloader reduces device security,
- unlocking can increase data leakage risk,
- unlocking may affect warranty or service,
- unlocking can cause data loss, boot failures, and unsupported ROM compatibility problems,
- Xiaomi HyperOS unlock access is limited and account-bound,
- Xiaomi Community is the official application path for HyperOS unlock privileges,
- account and device binding is part of the process,
- a valid SIM and wait period may apply,
- non-official unlock tools or services should not be trusted.

Reference URLs recorded for review:

- https://www.mi.com/global/support/faq/details/KA-533394
- https://www.mi.com/uk/support/faq/details/KA-07238/
- https://www.mi.com/th/support/faq/details/KA-535036/
- https://www.mi.com/th/support/faq/details/KA-535343/
- https://www.mi.com/global/support/faq/details/KA-523727/

Initial source review document:

```text
/docs/02-firmware-recovery/xiaomi-bootloader-unlock-source-review-2026-05-17.md
```

## Device state evidence already collected

- Device: Redmi Note 14 5G
- Android codename: `citrine`
- Xiaomi firmware naming observed: `beryl` / `beryl_dc`
- Platform: MediaTek MT6855
- Current stock OS family: HyperOS 3, Android 16
- Bootloader: locked
- Verified boot: green
- AVB device state: locked
- Verity mode: enforcing
- Current slot: `_b`
- Slot count: `2`
- Anti-rollback value reported by fastboot: `1`
- Dynamic partitions: enabled
- Virtual A/B: enabled
- Virtual A/B compression: enabled
- Treble: enabled
- CPU ABI: `arm64-v8a`

## Unlock evidence requirements

### Official procedure

- [ ] Xiaomi Community unlock path reviewed on the phone or web.
- [ ] Xiaomi account eligibility documented.
- [ ] Device and account binding requirement documented.
- [ ] SIM requirement documented.
- [ ] Wait period or pairing behavior documented.
- [ ] Device count and account limits documented.
- [ ] Unlock tool source documented.

### User and data readiness

- [ ] User accepts full data wipe risk.
- [ ] Important photos, downloads, documents, and app data are backed up.
- [ ] Password manager access is verified outside the phone.
- [ ] 2FA recovery is verified outside the phone.
- [ ] Banking, messaging, and identity apps are recoverable.
- [ ] SIM and eSIM implications are documented.
- [ ] Device encryption and screen lock implications are accepted.

### Stock rollback readiness

- [ ] Matching stock fastboot ROM path documented.
- [ ] Stock fastboot ROM SHA256 documented.
- [ ] Extracted firmware tree path documented.
- [ ] Firmware flash scripts identified but not executed.
- [ ] Flash script behavior reviewed.
- [ ] Anti-rollback implications reviewed.
- [ ] First rollback plan drafted.
- [ ] Relock policy documented, including no relock after modified images.

### First post-unlock test target

- [ ] First target selected.
- [ ] Target is minimal and reversible.
- [ ] Target does not require relock.
- [ ] Target rollback path is documented.
- [ ] Target success criteria are documented.
- [ ] Target failure criteria are documented.

### No-go conditions

Unlock remains no-go if any of these are true:

- Xiaomi account eligibility is unknown.
- Device binding cannot be confirmed.
- Wait period is unknown or not complete.
- Data backup is incomplete.
- Stock rollback plan is incomplete.
- First post-unlock target is undefined.
- First rollback target is undefined.
- Anti-rollback implications are unclear.
- Any required account or recovery credential depends only on the phone being unlocked.

## Current conclusion

No-go for bootloader unlock.

Research and evidence collection only.

<!-- preunlock-readonly-baseline:start -->
## Pre-unlock read-only baseline

Corrected pre-unlock read-only baseline evidence was collected before any bootloader unlock decision.

Evidence bundle:

```text
citrine-pre-unlock-readonly-state-20260517-101341.tar.gz
```

Baseline result:

- ADB readiness: `yes`
- Fastboot readiness: `yes`
- Device: Redmi Note 14 5G
- Android codename: `citrine`
- Platform: `mt6855`
- Android version: `16`
- Security patch: `2026-04-01`
- Current slot: `b`
- Slot count: `2`
- Bootloader unlocked: `no`
- Secure boot: `yes`
- Verified boot: `green`
- AVB device state: `locked`
- Flash locked: `1`
- Verity mode: `enforcing`
- Anti-rollback value reported by fastboot: `1`
- Bootloader version: `beryl_2605929bd_202604030659`
- Baseband: `MOLY.NR15.R3.MP.V167.P70`

Safety result:

- No bootloader unlock was performed.
- No flashing was performed.
- No userdata erase was performed.
- No DSU installation was performed.
- ADB and fastboot usage was read-only.

This baseline supports continued bootloader unlock planning, but it does not approve unlocking.
<!-- preunlock-readonly-baseline:end -->

<!-- backup-readiness-link:start -->
## Backup readiness evidence

Backup readiness is tracked separately in:

```text
/docs/02-firmware-recovery/backup-readiness-evidence.md
```

Current status: no-go until backup readiness is complete and reviewed.
<!-- backup-readiness-link:end -->
## Stock rollback plan status

A stock rollback plan has been documented but not executed:

```text
docs/02-firmware-recovery/stock-rollback-plan-not-executed.md
```

This reference does not approve bootloader unlock, flashing, userdata erase, DSU installation, Xiaomi flash script execution, or relock.


<!-- decision-0005-no-go-checkpoint:start -->
## Decision 0005 no-go checkpoint

Decision 0005 records the current project state as no-go for bootloader unlock because backup readiness and risk acceptance remain incomplete.

Current remaining blockers:

- Two-factor authentication recovery without relying only on this phone.
- Local app-exported data, where applicable.
- Data wipe risk acceptance.
- Warranty or service impact acceptance.
- Single-device risk acceptance.
- Rollback uncertainty acceptance.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Xiaomi flash script execution, or relock.
<!-- decision-0005-no-go-checkpoint:end -->

<!-- decision-0006-functional-phone-success:start -->
## Decision 0006 functional phone success criteria

Decision 0006 records that a usable phone is the success criterion, not merely a booting image.

Required future feasibility evidence includes:

- fully functional cellular behavior,
- Wi-Fi, Bluetooth, GNSS, cameras, audio, sensors, USB, charging, battery, thermal, and suspend behavior,
- legitimate Google Play Store access,
- understood Play Protect certification and Play Integrity implications,
- ability to install and use normal trusted applications,
- a clean Pixel-like or AOSP-style experience without unnecessary bloat,
- and a credible rollback path.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Xiaomi flash script execution, Google application sideloading, or relock.
<!-- decision-0006-functional-phone-success:end -->

<!-- decision-0007-functional-phone-feasibility:start -->
## Decision 0007 functional phone feasibility checkpoint

Decision 0007 records that bootloader unlock remains blocked until there is credible evidence for a fully functional phone path, not merely a booting image.

Required feasibility evidence includes exact device match, ROM source, maintainer credibility, base firmware, driver and vendor functionality, modem behavior, camera behavior, battery and thermal behavior, Google Play Store access, Play Protect or Play Integrity implications, trusted application behavior, clean software profile, and rollback feasibility.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- decision-0007-functional-phone-feasibility:end -->


<!-- functional-feasibility-source-review:start -->
## Functional feasibility source review

A first functional phone feasibility source review has been added:

```text
docs/12-functional-phone-feasibility/functional-phone-feasibility-source-review-2026-05-17.md
```

Current result: Halcyon is the strongest current feasibility lead for `beryl` / `citrine`, but there is not yet enough evidence to approve bootloader unlock or flashing. The next safe action is candidate-specific review only.
<!-- functional-feasibility-source-review:end -->

<!-- halcyon-candidate-review:start -->
## Halcyon candidate review

A first Halcyon `beryl` candidate review has been added:

```text
docs/12-functional-phone-feasibility/halcyon-beryl-candidate-review-2026-05-17.md
```

Current result: Halcyon remains the strongest research lead, but it is not approved for unlock or flashing because full phone functionality, Google Play and trusted application behavior, release integrity, and rollback feasibility are not proven.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- halcyon-candidate-review:end -->


<!-- halcyon-release-integrity-review:start -->
## Halcyon release integrity review

A Halcyon release integrity review has been added:

```text
docs/12-functional-phone-feasibility/halcyon-release-integrity-review-2026-05-17.md
```

Current result: release artifact integrity, functional phone behavior, Google trust behavior, clean software profile, and rollback feasibility remain incomplete. Halcyon remains research only.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- halcyon-release-integrity-review:end -->

<!-- step20-stock-rollback-dryrun-readiness:start -->
## Step 20 stock rollback dry-run readiness

A read-only stock rollback dry-run readiness evidence bundle has been collected:

```text
citrine-stock-rollback-dryrun-readiness-20260517-142604.tar.gz
```

Current rollback proof status: partial, not end-to-end proven.

What is stronger now:

- Local stock firmware package and checksum records exist.
- Extracted fastboot ROM anatomy was inspected.
- Flash script anatomy was reviewed without execution.
- Image inventory was captured.
- Current fastboot state was captured read-only.
- Product is `citrine`.
- Anti-rollback value is `1`.
- Bootloader unlocked state is `no`.
- Secure boot is `yes`.

What remains unproven:

- Successful full factory reflash.
- Recovery from hard brick.
- Recovery if fastboot is unavailable.
- MediaTek authenticated service-tool recovery.
- Safe relock after modifications.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, Xiaomi flash script execution, DSU installation, GSI installation, Google application sideloading, or relock.
<!-- step20-stock-rollback-dryrun-readiness:end -->

<!-- halcyon-source-retrieval-status:start -->
## Halcyon source retrieval status

A local source retrieval status document has been added:

```text
docs/12-functional-phone-feasibility/halcyon-source-retrieval-status-2026-05-17.md
```

Current result: Halcyon remains a candidate lead, but local retrieval of `wiki.hlcyn.co` is blocked by DNS `NXDOMAIN` from multiple resolvers. This is a source retrieval blocker, not a functional phone proof.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- halcyon-source-retrieval-status:end -->

<!-- alphadroid-candidate-review:start -->
## AlphaDroid candidate review

An AlphaDroid `beryl` / `citrine` candidate review has been added:

```text
docs/12-functional-phone-feasibility/alphadroid-beryl-candidate-review-2026-05-17.md
```

Current result: AlphaDroid is a candidate lead because public release metadata references Redmi Note 14 5G / POCO M7 Pro 5G `beryl` / `citrine`, Android 16, GApps, Vanilla, Vendor Boot, flashing instructions, source changelog, and device changelog. It is not approved for unlock or flashing because release integrity, functional phone behavior, Google trust behavior, and rollback feasibility remain incomplete.

Important blocker: the public release summary warns not to install if on HyperOS 3 and says to downgrade first. This device is currently on HyperOS 3, so the candidate remains blocked until required base firmware and downgrade risk are understood.

This checkpoint does not approve bootloader unlock, flashing, userdata erase, downgrade, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- alphadroid-candidate-review:end -->

<!-- alphadroid-source-evidence-status:start -->
## AlphaDroid source evidence status

AlphaDroid public source evidence was captured successfully:

```text
citrine-alphadroid-source-evidence-20260517-145828.tar.gz
```

Current result: AlphaDroid is now the strongest reachable candidate lead. The evidence confirms candidate artifacts and release metadata references for `beryl` / `citrine`, including GApps, Vanilla, and `vendor_boot.img` paths, but it also confirms active blockers: HyperOS 3 downgrade warning, missing release integrity proof, missing functional phone proof, and missing Google trust proof.

This checkpoint does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- alphadroid-source-evidence-status:end -->

<!-- alphadroid-artifact-metadata-status:start -->
## AlphaDroid artifact metadata status

AlphaDroid artifact metadata was captured successfully:

```text
citrine-alphadroid-artifact-metadata-20260517-175622.tar.gz
```

Current result: SourceForge metadata confirms the GApps ZIP, Vanilla ZIP, and `vendor_boot.img` artifacts are present and exposes HTTP size, timestamp, and ETag metadata. The capture intentionally avoided downloading ROM ZIP or image bodies.

Remaining blockers: no public checksum or signature evidence was found in the reduced metadata summary, functional phone behavior is not proven, Google trust behavior is not proven, the HyperOS 3 downgrade warning remains unresolved, and rollback remains only partially proven.

This checkpoint does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- alphadroid-artifact-metadata-status:end -->

<!-- alphadroid-release-integrity-status:start -->
## AlphaDroid release integrity status

Step 25 release integrity evidence was collected:

```text
citrine-alphadroid-release-integrity-20260517-183631.tar.gz
```

Current result: AlphaDroid artifact availability and HTTP metadata are confirmed, but release integrity remains incomplete because no useful public checksum or signature evidence was found for the checked artifact and common integrity paths.

This checkpoint does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- alphadroid-release-integrity-status:end -->

<!-- alphadroid-functional-public-evidence-status:start -->
## AlphaDroid functional public evidence status

Step 26 functional public evidence was collected:

```text
citrine-alphadroid-functional-public-evidence-20260517-185522.tar.gz
```

Current result: public evidence does not prove candidate-specific full phone functionality, Google Play Store behavior, Play Protect behavior, Play Integrity behavior, sensitive application behavior, HyperOS 3 downgrade safety, or rollback feasibility.

This checkpoint does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- alphadroid-functional-public-evidence-status:end -->

<!-- decision-0008-public-functional-evidence-insufficient:start -->
## Decision 0008 public functional evidence is insufficient

Decision 0008 records that public functional evidence is currently insufficient to justify bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

Current required evidence remains incomplete for full phone functionality, Google trust behavior, HyperOS 3 downgrade safety, release integrity, and rollback feasibility.

This checkpoint does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
<!-- decision-0008-public-functional-evidence-insufficient:end -->
