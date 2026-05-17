# Halcyon Release Integrity Review, 2026-05-17

## Current status

Halcyon remains a research candidate only.

This document does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Candidate source

Candidate: Halcyon for Redmi Note 14 5G / Redmi Note 14 SE / POCO M7 Pro 5G.

Device family: `beryl`.

Other codename listed by source: `citrine`.

Maintainer listed by source: `naokoshoto`.

Source page recorded for review:

```text
https://wiki.hlcyn.co/devices/beryl/
```

## Source-observed install path

The source page describes a path involving:

- bootloader unlock,
- `vendor_boot` flashing,
- recovery boot,
- data format,
- ADB sideload.

These are destructive or state-changing steps. They are not approved by this project.

## Release integrity status

Current status: incomplete.

The project has not yet identified and recorded:

- exact build artifact URL,
- exact build filename,
- build date,
- build size,
- release channel,
- checksum file,
- maintainer signature,
- detached signature,
- reproducible source tag,
- recovery image checksum,
- `vendor_boot` checksum,
- required base firmware,
- release notes,
- known bug list.

## Functional phone status

Current status: incomplete.

The project has not yet found enough non-secret public evidence for:

- cellular registration,
- mobile data,
- IMS, VoLTE, VoWiFi, or emergency calling behavior,
- Wi-Fi,
- Bluetooth,
- GNSS/location,
- cameras,
- audio and microphone,
- sensors,
- USB and charging,
- battery behavior,
- suspend behavior,
- thermal behavior.

## Google and trusted application status

Current status: incomplete.

The project has not yet found enough non-secret public evidence for:

- legitimate Google Play Store access,
- Play Protect certification behavior,
- Play Integrity behavior,
- sensitive application behavior,
- whether Google applications are distributed through a legitimate supported path,
- whether the ROM is shipped with Google apps, vanilla AOSP only, or optional Google packages.

## Clean software profile status

Current status: incomplete.

The project has not yet reviewed:

- default included apps,
- unwanted application profile,
- telemetry or analytics profile,
- update mechanism,
- whether the result is meaningfully Pixel-like or clean AOSP-style.

## Current conclusion

No-go for bootloader unlock.

Halcyon is a useful candidate lead, but there is not enough release integrity, functional phone, Google trust, clean software, or rollback evidence to justify destructive action on the only physical device.
