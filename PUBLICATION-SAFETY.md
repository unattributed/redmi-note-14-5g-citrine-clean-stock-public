# Publication Safety Notes

This repository is a sanitized public documentation and tooling mirror.

The private development repository may contain raw evidence, local diagnostic output, firmware archives, extracted firmware images, and private device-specific evidence. Those materials are intentionally excluded from this public mirror.

## Excluded from public mirror

- private evidence directories,
- evidence bundles,
- raw ADB evidence,
- raw fastboot evidence,
- full getprop output,
- full fastboot getvar output,
- firmware archives,
- extracted firmware images,
- raw super images,
- APK extraction output,
- files containing device serials, IMEI values, MAC addresses, SIM identifiers, account identifiers, or private user data.

## Public scope

This mirror is intended to publish:

- project documentation,
- safety boundaries,
- decision records,
- clean-stock package-management scripts,
- restore scripts,
- sanitized runbooks,
- non-secret technical notes.

## Current active path

The active project path is clean-stock HyperOS daily-driver validation with the bootloader locked.

This repository does not instruct users to unlock, flash, downgrade, wipe userdata, sideload Google applications, execute Xiaomi flash scripts, relock, or modify system images.
