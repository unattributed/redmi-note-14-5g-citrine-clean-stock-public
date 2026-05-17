# Decision 0007, Functional Phone Feasibility Evidence Required Before Unlock

## Context

Decision 0006 defined success as a usable phone, not merely a booting image.

The project target is a clean, Pixel-like or AOSP-style Android experience on Redmi Note 14 5G `citrine` / `beryl`, with legitimate Google Play Store access, trusted application behavior, and full phone functionality.

Current research indicates there may be community ROM activity for the `beryl` / `citrine` device family. That is useful, but it is not enough to justify bootloader unlock on the only physical device.

A booting ROM is not sufficient evidence. The project needs a credible functional phone path before any destructive action.

## Decision

Do not proceed to bootloader unlock based only on the existence of a ROM page, Telegram mention, Reddit claim, GSI boot report, or recovery sideload instructions.

Before unlock can be reconsidered, the project must collect non-secret feasibility evidence for:

- device identity match between this phone and any ROM target,
- base firmware requirement,
- bootloader unlock requirement,
- recovery or vendor_boot flashing requirement,
- data format requirement,
- rollback path,
- modem and cellular behavior,
- IMS, VoLTE, VoWiFi, and emergency calling risk where applicable,
- Wi-Fi,
- Bluetooth,
- GNSS/location,
- cameras,
- audio,
- microphones,
- sensors,
- USB data and charging,
- battery, suspend, thermal, and power behavior,
- Play Store access,
- Play Protect certification behavior,
- Play Integrity implications,
- normal trusted application installation,
- sensitive application risk,
- update cadence,
- maintainer credibility,
- known bugs,
- clean software profile and removable bloat,
- and rollback feasibility.

## Source basis

The following source classes are acceptable for feasibility research:

- official Android and Google documentation,
- official Xiaomi firmware and unlock documentation,
- ROM project device pages,
- maintainer repositories,
- release notes,
- issue trackers,
- XDA threads,
- community reports used only as weak supporting evidence.

The following source classes are not enough by themselves:

- screenshots without reproducible context,
- Telegram claims without release notes or bug lists,
- generic GSI boot screenshots,
- claims that Play Store opens without certification or integrity details,
- claims that everything works without modem, camera, sensor, battery, and rollback evidence.

## Current interpretation

A possible ROM path is now a research lead, not an approval path.

The project remains no-go for:

- bootloader unlock,
- flashing,
- userdata erase,
- DSU installation,
- GSI installation,
- Xiaomi flash script execution,
- Google application sideloading,
- or relock.

## Reopen condition

A later decision record may reconsider unlock only after:

1. backup readiness blockers are closed or explicitly accepted,
2. functional phone feasibility evidence is documented,
3. Google Play and trusted application behavior risks are documented,
4. rollback path is reviewed,
5. the user explicitly accepts remaining risks,
6. and the next destructive step is narrowly scoped.

## Current conclusion

No-go for bootloader unlock.

Continue feasibility research only.
