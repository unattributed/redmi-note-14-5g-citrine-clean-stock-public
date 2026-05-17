# Halcyon `beryl` Candidate Review, 2026-05-17

## Current status

Halcyon is the strongest current feasibility lead for the Redmi Note 14 5G `citrine` / `beryl` device family.

This review does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Source basis

Reviewed source:

```text
https://wiki.hlcyn.co/devices/beryl/
```

The Halcyon device page identifies:

- Device family: Redmi Note 14 5G / Redmi Note 14 SE / POCO M7 Pro 5G.
- Primary codename: `beryl`.
- Other codename: `citrine`.
- Halcyon version: Bloom.
- Maintainer: `naokoshoto`.
- Install path involving `vendor_boot`, recovery, format data, and ADB sideload.

## Positive feasibility signals

- The candidate page explicitly maps `beryl` and `citrine` together.
- The page names the same commercial device family as this project.
- A maintainer is listed.
- A published install method exists.
- The install method is normal for a custom Android ROM path: bootloader unlock, recovery image, format data, ADB sideload.

## Current evidence gaps

The page does not prove the project success target.

Missing evidence:

- Full modem and cellular registration behavior.
- Data connectivity stability.
- IMS, VoLTE, VoWiFi, and emergency calling behavior.
- Wi-Fi stability.
- Bluetooth stability.
- GNSS/location behavior.
- Front and rear camera behavior.
- Audio and microphone behavior.
- Sensors.
- USB data and charging behavior.
- Battery drain, suspend, thermal, and power management behavior.
- Release checksum or integrity process.
- Known bug list.
- Google Play Store access path.
- Play Protect certification behavior.
- Play Integrity behavior.
- Sensitive application behavior.
- Clean software and bloat profile.
- Verified rollback procedure.

## Google trust concern

Google Play Store access is not just a question of whether a ROM boots.

The project success target requires legitimate Google Play Store access and normal trusted application behavior. A custom ROM candidate must therefore be evaluated for Play Protect certification behavior, Play Integrity implications, Google application distribution model, and sensitive application compatibility.

AOSP and GSI compatibility alone do not prove Google Mobile Services licensing, Play Protect certification, or Play Integrity behavior.

## Install path risk

The Halcyon page describes a path that includes:

- Bootloader unlock.
- Flashing `vendor_boot`.
- Booting recovery.
- Formatting data.
- ADB sideload.

These are destructive or state-changing operations. This project is not approved to perform them yet.

## Current candidate decision

Halcyon remains a candidate for research only.

Do not unlock or flash based only on this page.

## Evidence required before reconsidering unlock

Before Halcyon can be considered as an unlock justification, the project needs non-secret evidence for:

- Exact build package and release source.
- Release integrity method or checksum.
- Required base firmware.
- Known bugs.
- Functional phone behavior.
- Google Play Store and trusted app behavior.
- Rollback feasibility.
- User acceptance of remaining risks.

## Current conclusion

No-go for bootloader unlock.

Continue candidate-specific research only.
