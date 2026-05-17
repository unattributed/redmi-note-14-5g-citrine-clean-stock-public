# Functional Phone Feasibility Source Review Runbook

This runbook is for research only. It does not approve unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Purpose

Collect non-secret evidence showing whether Redmi Note 14 5G `citrine` / `beryl` has a credible path to a fully usable clean Android experience.

## Research targets

### Device identity

Record whether a ROM target exactly matches this device:

- Redmi Note 14 5G
- model family `24094RAD4G` or matching regional variant
- Android codename `citrine`
- Xiaomi firmware naming `beryl` / `beryl_dc`
- MediaTek platform family
- current slot model and dynamic partition assumptions

### ROM path

For each candidate ROM or image, record:

- project name,
- source URL,
- maintainer identity if public,
- target codename,
- required base firmware,
- Android version,
- install method,
- whether vendor_boot, boot, init_boot, dtbo, vbmeta, or recovery images are touched,
- whether data format is required,
- update cadence,
- known bugs,
- rollback notes,
- and whether the project publishes checksums.

### Functional phone evidence

Record evidence for:

- cellular registration,
- 4G or 5G behavior,
- IMS, VoLTE, VoWiFi, and emergency call risk where applicable,
- Wi-Fi,
- Bluetooth,
- GNSS/location,
- cameras,
- audio and microphones,
- sensors,
- USB data and charging,
- battery drain,
- suspend and wake,
- thermal behavior,
- fingerprint if required,
- NFC if present,
- and display refresh behavior.

### Google and application trust evidence

Record evidence for:

- whether Google apps are included through a legitimate path,
- whether Play Store works,
- whether Play Protect certification is reported as certified or not certified,
- whether Play Integrity behavior is documented,
- whether banking or sensitive apps are expected to work,
- and whether the ROM depends on root, spoofing, uncertified Google packages, or unsafe workarounds.

### Clean software evidence

Record evidence for:

- included apps,
- bloat level,
- Pixel-like or AOSP-style user experience,
- removable extras,
- telemetry concerns,
- and whether vendor components are retained only where needed for hardware functionality.

## Output

Update:

```text
docs/12-functional-phone-feasibility/README.md
```

Do not record private account details, phone numbers, personal identifiers, or credentials.
