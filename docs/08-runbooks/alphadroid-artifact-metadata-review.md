# AlphaDroid Artifact Metadata Review Runbook

This runbook is research only. It does not install AlphaDroid or modify the phone.

## Allowed

- Capture the public SourceForge folder listing.
- Capture HTTP HEAD responses for candidate artifacts.
- Record file names, redirects, content headers, and metadata indicators.
- Search public metadata for checksum, signature, and integrity hints.

## Not allowed

- Downloading ROM ZIP artifact bodies during metadata review.
- Flashing any image.
- Unlocking the bootloader.
- Downgrading firmware.
- Formatting userdata.
- Installing DSU or GSI images.
- Sideloading Google applications.
- Relocking the bootloader.

## Required interpretation

A reachable artifact URL is not proof of release integrity, full phone functionality, Google trust behavior, or rollback feasibility.
