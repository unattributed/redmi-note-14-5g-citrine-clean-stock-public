# AlphaDroid Source Evidence Status, 2026-05-17

## Current status

AlphaDroid public source evidence was captured successfully from the Parrot workstation.

Evidence bundle:

```text
citrine-alphadroid-source-evidence-20260517-145828.tar.gz
```

## Captured public sources

The source collector captured non-empty local copies of:

- AlphaDroid SourceForge project page.
- AlphaDroid SourceForge files page.
- Telemetr AlphaDroid releases page.
- Telemetr AlphaDroid release posts page.
- Google Mobile Services documentation.
- Google Play Protect certification documentation.
- Google Play Integrity documentation.

## Candidate evidence strengthened

The captured pages strengthen AlphaDroid as a real candidate lead because the local evidence contains references to:

- `AlphaDroid 4.4 Official`.
- `Android 16`.
- `REDMI Note 14 5G / POCO M7 Pro 5G`.
- `beryl/citrine`.
- `GApps` and `Vanilla` build options.
- `vendor_boot.img`.
- SourceForge artifact paths for `AlphaDroid-16-20260423-gapps-beryl-v4.4.zip`, `AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip`, and `vendor_boot.img`.
- Flashing instructions link.
- Source changelog and device changelog links.
- Maintainer reference to `Naoko Shoto`.

## Candidate blockers still active

The same captured evidence keeps AlphaDroid blocked for this project because:

- The public release notes warn not to install if on HyperOS 3 and to downgrade first.
- This project device is currently on HyperOS 3.
- The collector found no `sha256` or `checksum` keyword hits in the captured pages.
- Functional phone behavior is still not proven.
- Google Play Store, Play Protect, Play Integrity, and sensitive application behavior are still not proven.
- The required downgrade path and rollback risk are not understood.
- Vulkan or GPU behavior remains a flagged research item because the captured release text references missing Vulkan fixes until HOS3.

## Current interpretation

AlphaDroid is now the strongest reachable candidate lead.

It is still not a green light for bootloader unlock, downgrade, flashing, Google application sideloading, or permanent replacement of the stock image.

## Next evidence needed

The next efficient proof step is exact artifact metadata and release integrity review:

- Confirm the exact SourceForge artifact URLs.
- Capture file sizes and timestamps for the GApps, Vanilla, and `vendor_boot.img` artifacts.
- Determine whether SourceForge or the maintainer publishes SHA256, checksums, signatures, or reproducible release metadata.
- Capture the raw source changelog and device changelog.
- Capture the flashing instruction page without executing it.
- Determine whether the HyperOS 3 downgrade warning blocks this device entirely.

## Current conclusion

Track 2 remains no-go.

Continue source evidence collection only.
