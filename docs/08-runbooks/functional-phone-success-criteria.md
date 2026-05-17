# Functional Phone Success Criteria Runbook

This runbook defines what must be proven before a custom Android image can be considered useful for this project.

It does not unlock, flash, erase userdata, install DSU, bind a Xiaomi account, or modify the phone.

## Success definition

A usable phone is success.

A booting image is not success unless the phone remains functional as a daily driver.

## Required evidence before any replacement image is accepted

### Hardware and radio

- Cellular voice works.
- Mobile data works.
- SIM is detected.
- Carrier registration works.
- 4G or 5G behavior is acceptable.
- IMS behavior is understood where required.
- Wi-Fi works.
- Bluetooth works.
- GNSS/location works.
- Cameras work.
- Audio works.
- Microphones work.
- Sensors work.
- USB data and charging work.
- Battery, suspend, thermal, and power behavior are acceptable.

### Google and application trust

- Google Play Store access is available through a legitimate path.
- Play Protect or device certification status is understood.
- Play Integrity implications are understood.
- Sensitive apps are not assumed to work until tested.
- No unsafe Google application sideloading path is treated as success.

### Clean software target

- Minimal unwanted applications.
- No unnecessary OEM promotional software.
- Pixel-like or clean AOSP-style user experience.
- Required vendor components remain acceptable when needed for hardware functionality.

## Explicit non-success conditions

The following are not success:

- GSI boots but modem fails.
- GSI boots but cameras fail.
- AOSP boots but Google Play cannot be used normally.
- Image boots but app trust or Play Integrity breaks required apps.
- Image boots but power management is unstable.
- Image boots but rollback is unclear.

## Output

Future research should update the device feasibility documentation with non-secret evidence only.
