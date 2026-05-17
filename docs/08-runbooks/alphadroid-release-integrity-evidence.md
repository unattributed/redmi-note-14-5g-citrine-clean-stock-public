# AlphaDroid Release Integrity Evidence Runbook

This runbook is research only. It does not install AlphaDroid or modify the phone.

## Allowed

- Capture public SourceForge metadata.
- Capture HTTP HEAD traces for known artifacts.
- Look for checksum, signature, README, changelog, and release metadata references.
- Record non-secret findings.

## Not allowed

- Bootloader unlock.
- Downgrade.
- Flashing.
- Formatting userdata.
- DSU or GSI installation.
- Google application sideloading.
- Downloading full ROM ZIP or image bodies as part of this step.
- Relocking.

## Purpose

Step 25 determines whether the AlphaDroid candidate has a trustworthy public release integrity trail before any destructive work is considered.

## Required evidence

- Exact artifact names.
- Artifact HTTP metadata.
- Checksum source, if published.
- Signature source, if published.
- Release notes or changelog source.
- Known bug source.

## Current rule

No checksum or signature evidence means release integrity remains incomplete.
