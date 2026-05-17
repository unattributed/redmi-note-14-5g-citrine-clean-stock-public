# AlphaDroid Functional Public Evidence Status, 2026-05-17

## Current status

Step 26 collected read-only public evidence for the AlphaDroid `beryl` / `citrine` candidate.

Evidence bundle:

```text
citrine-alphadroid-functional-public-evidence-20260517-185522.tar.gz
```

## Scope

This was public source review only.

It did not:

- modify the phone,
- unlock the bootloader,
- download ROM artifacts,
- flash images,
- downgrade firmware,
- install DSU,
- sideload Google applications.

## Sources captured

The collector captured public pages for:

- Android GSI documentation,
- Google Mobile Services documentation,
- Google Play Integrity documentation,
- Google Play Protect certification documentation,
- SourceForge AlphaDroid project page,
- SourceForge AlphaDroid `beryl` folder page,
- Telemetr AlphaDroid releases page.

## Functional evidence result

Functional phone behavior remains unproven.

The capture found generic references across public documentation, but it did not find candidate-specific proof that AlphaDroid on this exact `beryl` / `citrine` device provides acceptable daily-driver functionality.

The following remain unproven for the candidate:

- cellular registration,
- mobile data,
- IMS, VoLTE, VoWiFi, and emergency calling behavior,
- Wi-Fi behavior,
- Bluetooth behavior,
- GNSS/location behavior,
- camera behavior,
- audio and microphone behavior,
- sensor behavior,
- USB and charging behavior,
- battery, suspend, and thermal behavior,
- Vulkan or GPU behavior,
- fingerprint or biometric behavior,
- sensitive application behavior.

## Google trust result

Google trust behavior remains unproven for the candidate.

The captured Google documentation reinforces that Google Mobile Services, Play Protect certification, and Play Integrity behavior are separate constraints. It does not prove that the AlphaDroid GApps build provides legitimate Play Store access, Play Protect certification behavior, Play Integrity behavior, or normal sensitive-application behavior on this device.

The following remain unproven:

- legitimate Google Play Store path,
- Play Protect certification behavior,
- Play Integrity behavior,
- sensitive application compatibility,
- whether the GApps build is sufficient for the user's Google-trusted application requirement.

## Downgrade and install risk result

Downgrade and install risks remain unresolved.

The project continues to treat the following as active blockers:

- HyperOS 3 downgrade warning,
- format-data workflow,
- `vendor_boot` dependency,
- rollback feasibility,
- no-relock safety boundary.

The Step 26 capture did not resolve those blockers.

## Current interpretation

Step 26 is useful because it confirms that public-source functional proof is still missing.

It does not clear the functional phone gate.

It does not clear the Google-trust gate.

It does not clear the downgrade-risk gate.

## Current conclusion

Track 2 remains no-go.

AlphaDroid remains the strongest reachable candidate lead, but it is not approved for bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
