# Decision 0008, Public Functional Evidence Is Insufficient

## Context

The project has two proof tracks before any destructive action is allowed:

- Track 1, factory rollback proof.
- Track 2, functional phone image proof.

Track 1 is stronger after the stock rollback dry-run readiness evidence, but it is still not end-to-end proven.

Track 2 has identified AlphaDroid as the strongest reachable candidate lead for Redmi Note 14 5G / POCO M7 Pro 5G `beryl` / `citrine`.

The project has now captured public AlphaDroid evidence for:

- Candidate source evidence.
- Artifact HTTP metadata.
- Release integrity checks.
- Public functional evidence.

## Decision

Public evidence is currently insufficient to justify bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

A booting image is not the success target.

A usable phone is the success target.

The project remains no-go because public evidence still does not prove:

- Full cellular behavior.
- IMS, VoLTE, VoWiFi, and emergency calling behavior.
- Camera behavior.
- Wi-Fi, Bluetooth, GNSS, sensors, audio, microphone, USB, and charging behavior.
- Battery, suspend, and thermal behavior.
- Vulkan or GPU behavior.
- Google Play Store behavior.
- Play Protect behavior.
- Play Integrity behavior.
- Sensitive application behavior.
- HyperOS 3 downgrade safety.
- Release integrity through checksums, signatures, or maintainer-signed metadata.
- Rollback feasibility beyond the current partial proof.

## Required evidence before reopening unlock consideration

A future decision may reconsider this only if credible evidence is collected for the exact device family and candidate image.

Minimum reopen evidence:

- Exact artifact identity for the candidate ROM and supporting images.
- Required base firmware clearly identified.
- HyperOS 3 downgrade requirement resolved or ruled out for this device.
- Maintainer or release documentation describing known bugs.
- Evidence that modem, data, IMS-related behavior, cameras, audio, sensors, GNSS, Wi-Fi, Bluetooth, USB, charging, battery, suspend, and thermal behavior are acceptable.
- Evidence describing Google application distribution model.
- Evidence describing Play Protect and Play Integrity behavior.
- Evidence describing sensitive application risk.
- Release integrity proof through checksum, signature, or equivalent trusted metadata.
- Rollback path stronger than current partial proof.

## Allowed next actions

- Ask maintainers for non-secret functional evidence.
- Ask maintainers for checksums, signatures, release notes, and known bug lists.
- Review public maintainer channels and release posts.
- Review user reports, but treat them as weak evidence unless they include exact build, base firmware, and device model details.
- Record only non-secret evidence in the repository.

## Explicitly not allowed

- Bootloader unlock.
- `fastboot flashing unlock`.
- `fastboot oem unlock`.
- Downgrading firmware.
- Flashing any partition.
- Running Xiaomi `flash_all*.sh` scripts.
- Erasing userdata.
- Starting DSU installation.
- Installing a GSI.
- Installing AlphaDroid.
- Google application sideloading.
- Relocking the bootloader after any modified image is used.

## Current conclusion

No-go for bootloader unlock.

No-go for flashing.

No-go for downgrade.

Continue maintainer-level and source-level evidence collection only.
