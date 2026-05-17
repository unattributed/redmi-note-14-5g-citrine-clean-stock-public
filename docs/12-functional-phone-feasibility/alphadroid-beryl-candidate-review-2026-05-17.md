# AlphaDroid beryl Candidate Review, 2026-05-17

## Current status

AlphaDroid is a new candidate lead for Redmi Note 14 5G / POCO M7 Pro 5G `beryl` / `citrine`.

This document is research only. It does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, downgrade, rollback execution, or relock.

## Source basis

Public search results show an AlphaDroid 4.4 official Android 16 release entry for Redmi Note 14 5G / POCO M7 Pro 5G `beryl` / `citrine`.

The observed source summary includes:

- ROM: AlphaDroid 4.4 official.
- Android: 16.
- Device: Redmi Note 14 5G / POCO M7 Pro 5G.
- Codenames: `beryl` / `citrine`.
- Release date: 2026-04-24.
- Maintainer: Naoko Shoto.
- Download categories: GApps, Vanilla, Vendor Boot.
- Documentation categories: flashing instructions, support, source changelog, device changelog.
- Notes include: do not install if on HyperOS 3, downgrade first.
- Notes include: firmware included.
- Notes include: no Vulkan fixes until HOS3.

## Why this matters

This candidate is more specific than a generic ROM mention because it references:

- exact device family,
- exact codenames,
- Android version,
- maintainer name,
- GApps and Vanilla variants,
- vendor boot artifact,
- and release notes.

However, it is still not enough to approve unlock or flashing.

## Current blockers

### HyperOS 3 base conflict

The device currently runs HyperOS 3. The public AlphaDroid release summary says not to install if on HyperOS 3 and to downgrade first.

That is a hard blocker until the required base firmware is known and rollback or downgrade risk is understood.

### Release integrity incomplete

The project has not yet captured:

- exact download URL,
- exact artifact name,
- SHA256 checksum,
- signature or release integrity mechanism,
- maintainer hosted release page,
- source changelog details,
- device changelog details.

### Functional phone evidence incomplete

The project has not yet captured evidence for:

- cellular registration,
- mobile data,
- IMS, VoLTE, VoWiFi, and emergency calling risk,
- Wi-Fi,
- Bluetooth,
- GNSS/location,
- cameras,
- audio and microphones,
- sensors,
- USB and charging,
- battery, suspend, and thermal behavior,
- Vulkan or GPU behavior.

### Google and trusted application evidence incomplete

The project has not yet captured evidence for:

- legitimate Google Play Store path,
- Play Protect behavior,
- Play Integrity behavior,
- sensitive application compatibility,
- whether GApps variant is licensed, unofficial, bundled, or separately installed.

## Current interpretation

AlphaDroid is a stronger candidate lead than a generic community claim, but it is not a green light.

The HyperOS 3 downgrade warning is especially important because this project currently has one physical device and rollback is only partially proven.

## Current conclusion

No-go for bootloader unlock.

No-go for flashing.

Continue candidate-specific source evidence collection only.

<!-- step23-source-evidence:start -->
## Step 23 source evidence update

Evidence bundle:

```text
citrine-alphadroid-source-evidence-20260517-145828.tar.gz
```

Result: candidate evidence is stronger, but still no-go.

The captured evidence identifies AlphaDroid `beryl` / `citrine` release metadata and artifact references for GApps, Vanilla, and `vendor_boot.img`. The same evidence preserves the HyperOS 3 downgrade warning and does not provide release integrity, full functional phone, Google trust, or rollback proof.
<!-- step23-source-evidence:end -->
