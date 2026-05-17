# Functional Phone Feasibility Source Review, 2026-05-17

## Current status

Functional phone feasibility is not proven.

This document records a non-destructive source review only. It does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Success definition

A usable phone is success. A booting image is not success.

The target outcome requires all of the following:

- fully functional phone behavior,
- legitimate Google Play Store access,
- trusted application install behavior,
- clean Pixel-like or AOSP-style user experience,
- no unnecessary bloat,
- acceptable vendor components where required for hardware functionality,
- and a credible rollback path.

## Source review summary

### Halcyon beryl device page

A Halcyon device page exists for Redmi Note 14 5G / 14 SE / POCO M7 Pro 5G using device family `beryl`, and it lists `citrine` as another codename.

Useful evidence from the page:

- device family appears to match `beryl` / `citrine`,
- a maintainer is listed,
- a Halcyon version is listed,
- install instructions are published,
- the install flow includes flashing `vendor_boot`, formatting data, and ADB sideload.

Limitations:

- the page is not proof of full daily-driver functionality,
- the page does not prove cellular, IMS, VoLTE, VoWiFi, emergency calling, camera, battery, thermal, Play Store, Play Protect, or Play Integrity behavior,
- the page does not remove the need for backup readiness or risk acceptance,
- the page does not prove compatibility with this exact installed firmware state.

### Community ROM reports

Community reports mention possible ROM activity for the Redmi Note 14 5G / `beryl` family, including names such as Halcyon, PixelOS, Lineage-style builds, Axion, and other unofficial builds.

Useful evidence:

- there appears to be active community interest,
- there may be ROMs or test builds for the device family,
- some users claim PixelOS or Lineage-style firmware exists.

Limitations:

- community reports are not authoritative,
- some reports mention bugs or instability,
- device variants can differ,
- Telegram-only distribution is not enough for this project without release integrity and maintainer evidence,
- these claims do not prove Google trust, Play Store certification behavior, or sensitive application behavior.

### Google trust and Play Store constraints

A clean AOSP image does not automatically provide licensed Google Mobile Services or a certified Play Store experience.

This project must treat the following as separate feasibility requirements:

- legitimate Google Play Store access,
- Play Protect certification behavior,
- Play Integrity behavior,
- sensitive application compatibility,
- and avoiding unsafe Google application sideload assumptions.

## Candidate status

| Candidate | Current status | Why it is not enough yet |
| --- | --- | --- |
| Halcyon for `beryl` / `citrine` | Feasibility lead | Published device page exists, but daily-driver functionality and Google trust behavior are not proven. |
| PixelOS claims | Weak lead | Community claims exist, but no validated exact-device source, checksum, maintainer, or functionality matrix is recorded. |
| Lineage-style claims | Weak lead | Community claims exist, but no validated exact-device source, checksum, maintainer, or functionality matrix is recorded. |
| Generic GSI | Insufficient | A GSI can test Treble behavior, but it is not proof of full phone functionality or Google trust. |

## Required next evidence

Before unlock can be reconsidered, the project needs a candidate-specific source review for at least one ROM path.

For each candidate, collect:

- exact device codename and supported model variants,
- base firmware requirement,
- maintainer identity or project credibility,
- release source,
- checksum or integrity evidence,
- install method,
- known bugs,
- cellular and modem status,
- IMS, VoLTE, VoWiFi, and emergency calling risk notes,
- Wi-Fi and Bluetooth status,
- GNSS/location status,
- camera status,
- audio and microphone status,
- sensor status,
- USB, charging, battery, suspend, and thermal status,
- Google Play Store path,
- Play Protect certification behavior,
- Play Integrity behavior,
- sensitive application risk,
- bloat or clean software profile,
- rollback path.

## Current conclusion

No-go for bootloader unlock.

Halcyon is the strongest current feasibility lead, but it is not enough to unlock or flash. The next safe action is a Halcyon-specific candidate review, still without downloading untrusted ROMs for flashing, unlocking, or modifying the phone.
