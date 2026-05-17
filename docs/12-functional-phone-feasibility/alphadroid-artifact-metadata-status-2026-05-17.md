# AlphaDroid Artifact Metadata Status, 2026-05-17

## Current status

Step 24 completed successfully after replacing the artifact collector with a strict no-body metadata capture.

The evidence bundle is:

```text
citrine-alphadroid-artifact-metadata-20260517-175622.tar.gz
```

## What was captured

The Step 24 evidence captures SourceForge public metadata for the current AlphaDroid `beryl` artifacts without downloading ROM ZIP or image bodies.

Captured artifact metadata:

| Artifact | Metadata result |
| --- | --- |
| `AlphaDroid-16-20260423-gapps-beryl-v4.4.zip` | present in SourceForge folder listing, HEAD request returned `Content-Length: 2488312508`, `last-modified: Thu, 23 Apr 2026 17:08:17 GMT`, and `etag: "69ea5201-9450a2bc"` |
| `AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip` | present in SourceForge folder listing, HEAD request returned `Content-Length: 1667461634`, `last-modified: Thu, 23 Apr 2026 17:00:41 GMT`, and `etag: "69ea5039-63637202"` |
| `vendor_boot.img` | present in SourceForge folder listing, HEAD request returned `Content-Length: 67108864`, `last-modified: Thu, 23 Apr 2026 17:03:48 GMT`, and `etag: "69ea50f4-4000000"` |

## Integrity status

The captured SourceForge folder metadata did not show public checksum or signature evidence in the reduced metadata summary.

Observed keyword counts from the captured folder listing:

- `sha256`: `0`
- `checksum`: `0`
- `signature`: `0`

This means artifact presence and HTTP metadata are stronger now, but release integrity is still incomplete. Before any unlock or flashing decision, the project still needs either published checksums, signatures, maintainer integrity statements, or a deliberately documented acceptance of unsigned release risk.

## Functional phone status

This step does not prove functional phone behavior.

Still unproven:

- cellular registration,
- mobile data,
- IMS, VoLTE, VoWiFi, and emergency calling behavior,
- Wi-Fi,
- Bluetooth,
- GNSS/location,
- cameras,
- audio and microphones,
- sensors,
- USB and charging,
- battery, suspend, and thermal behavior,
- Vulkan or GPU behavior.

## Google trust status

This step does not prove:

- legitimate Google Play Store behavior,
- Play Protect certification behavior,
- Play Integrity behavior,
- sensitive application compatibility,
- whether the GApps artifact provides a supported or acceptable Google application path for this project.

## Current interpretation

AlphaDroid remains the strongest reachable candidate lead.

The project now has exact artifact metadata for the GApps ZIP, Vanilla ZIP, and `vendor_boot.img`, but this is still not enough to approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Current conclusion

Track 2 remains no-go.

Continue source evidence collection only.
