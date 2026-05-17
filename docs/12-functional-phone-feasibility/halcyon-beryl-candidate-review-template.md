# Halcyon Beryl Candidate Review Template

## Current status

Not completed.

This document is a candidate review template only. It does not approve bootloader unlock, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Candidate identity

- Candidate ROM name: Halcyon
- Candidate device family: `beryl`
- Alternate codename listed by candidate source: `citrine`
- Local device codename: `citrine`
- Local Xiaomi firmware naming observed: `beryl` / `beryl_dc`
- Local model observed by ADB: `24094RAD4G`

## Evidence checklist

### Source and release integrity

- [ ] Official candidate page archived in notes.
- [ ] Download source identified.
- [ ] Maintainer identified.
- [ ] Release version identified.
- [ ] Required base firmware identified.
- [ ] Checksums or release integrity method identified.
- [ ] Known bug list identified.

### Install path risk

- [ ] Recovery or `vendor_boot` requirement understood.
- [ ] Format-data requirement understood.
- [ ] ADB sideload requirement understood.
- [ ] Rollback path mapped before any install.
- [ ] No-relock warning understood.

### Functional phone requirements

- [ ] Cellular registration evidence found.
- [ ] Data connectivity evidence found.
- [ ] IMS, VoLTE, VoWiFi, and emergency calling risk reviewed.
- [ ] Wi-Fi evidence found.
- [ ] Bluetooth evidence found.
- [ ] GNSS/location evidence found.
- [ ] Camera evidence found.
- [ ] Audio and microphone evidence found.
- [ ] Sensor evidence found.
- [ ] USB and charging evidence found.
- [ ] Battery, suspend, and thermal evidence found.

### Google and trusted application requirements

- [ ] Google Play Store access path identified.
- [ ] Play Protect certification behavior understood.
- [ ] Play Integrity behavior understood.
- [ ] Sensitive application risk understood.
- [ ] No unsafe Google application sideload assumption is treated as success.

### Clean software profile

- [ ] Bloat profile reviewed.
- [ ] Pixel-like or clean AOSP-style experience assessed.
- [ ] Required vendor components accepted where needed for hardware support.

## Candidate conclusion

No-go until this candidate has evidence for functional phone behavior, Google trust behavior, release integrity, and rollback feasibility.
