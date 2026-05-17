# Functional Phone Feasibility

## Current status

Feasibility is not yet proven.

The project has defined success as a usable phone, not merely a booting image.

## Current research leads

### Stock firmware and rollback

The stock firmware path exists locally and has been documented elsewhere in the repository. This supports rollback planning but does not prove a custom ROM path.

### Community ROM lead, Halcyon for `beryl` / `citrine`

A Halcyon device page exists for Redmi Note 14 5G / 14 SE / POCO M7 Pro 5G `beryl`, and it lists `citrine` as another codename. The page includes an installation path involving fastboot, `vendor_boot`, recovery, data format, and ADB sideload.

Current interpretation:

- This is a useful research lead.
- It suggests the device family may have a maintained ROM path.
- It does not by itself prove that this exact phone will be a fully functional daily driver.
- It does not by itself prove Google Play certification, Play Integrity behavior, modem behavior, camera quality, battery behavior, or rollback safety.

### Community reports

Community reports mention possible ROMs such as Halcyon, PixelOS, Lineage-style builds, Axion, and other unofficial builds for Redmi Note 14 5G / `beryl` style devices.

Current interpretation:

- These are weak supporting signals only.
- Community reports must not be treated as approval for unlock or flashing.
- Any candidate must be checked against release notes, known bugs, maintainer source, target codename, base firmware, and rollback requirements.

## Google trust constraint

A Pixel-like experience is a user experience target, not a literal Pixel factory image target.

A clean Android image is not enough if it breaks Google Play Store access, Play Protect certification behavior, Play Integrity behavior, or normal trusted application installation.

AOSP and GSI images do not automatically provide licensed Google Mobile Services.

## Required evidence before unlock can be reconsidered

- Candidate ROM name and source.
- Exact device codename match.
- Required base firmware.
- Maintainer and update cadence.
- Published install method.
- Checksums or release integrity information.
- Known bugs.
- Modem and cellular evidence.
- IMS, VoLTE, VoWiFi, and emergency calling risk notes where applicable.
- Wi-Fi and Bluetooth evidence.
- Camera evidence.
- Audio and microphone evidence.
- Sensor evidence.
- Battery, suspend, and thermal evidence.
- Google Play Store access evidence.
- Play Protect certification or uncertified behavior evidence.
- Play Integrity implications.
- Sensitive app risk.
- Clean software profile.
- Rollback plan.

## Current blockers

- No candidate ROM has been validated as fully functional for this exact device.
- Google Play and trusted application behavior are not proven.
- Driver and vendor support are not proven.
- Remaining backup and risk acceptance blockers still exist.

## Current conclusion

No-go for bootloader unlock.

Continue research only.


## Current source review

- [Functional phone feasibility source review, 2026-05-17](functional-phone-feasibility-source-review-2026-05-17.md)
- [Halcyon beryl candidate review template](halcyon-beryl-candidate-review-template.md)

Current conclusion: Halcyon is the strongest current feasibility lead, but no candidate is approved for unlock or flashing.

## Halcyon candidate review

- [Halcyon `beryl` candidate review, 2026-05-17](halcyon-beryl-candidate-review-2026-05-17.md)

Current conclusion: Halcyon is a research candidate only. It is not approved for unlock or flashing because functional phone behavior, Google trust behavior, release integrity, and rollback feasibility are not proven.


## Halcyon release integrity review

- [Halcyon release integrity review, 2026-05-17](halcyon-release-integrity-review-2026-05-17.md)

Current conclusion: Halcyon remains a research candidate only. Release integrity, functional phone behavior, Google trust behavior, clean software profile, and rollback feasibility are not proven.
- [Halcyon source retrieval status, 2026-05-17](halcyon-source-retrieval-status-2026-05-17.md)

## AlphaDroid candidate review

- [AlphaDroid beryl candidate review, 2026-05-17](alphadroid-beryl-candidate-review-2026-05-17.md)

Current conclusion: AlphaDroid is a candidate lead, but it is not approved for unlock or flashing. The HyperOS 3 downgrade warning is a hard blocker until required base firmware and downgrade risk are understood.
- [AlphaDroid source evidence status, 2026-05-17](alphadroid-source-evidence-status-2026-05-17.md)

<!-- alphadroid-artifact-metadata-status:start -->
## AlphaDroid artifact metadata status

- [AlphaDroid artifact metadata status, 2026-05-17](alphadroid-artifact-metadata-status-2026-05-17.md)

Current result: exact SourceForge metadata was captured for the AlphaDroid GApps, Vanilla, and `vendor_boot.img` artifacts without downloading ROM bodies. Release integrity, functional phone behavior, Google trust behavior, downgrade risk, and rollback feasibility remain incomplete.
<!-- alphadroid-artifact-metadata-status:end -->

<!-- alphadroid-release-integrity-status:start -->
## AlphaDroid release integrity status

- [AlphaDroid release integrity status, 2026-05-17](alphadroid-release-integrity-status-2026-05-17.md)

Current result: exact public artifact HTTP metadata is confirmed for the AlphaDroid GApps ZIP, Vanilla ZIP, and `vendor_boot.img`, but no useful public checksum or signature evidence was found. Release integrity remains incomplete.
<!-- alphadroid-release-integrity-status:end -->

<!-- alphadroid-functional-public-evidence-status:start -->
## AlphaDroid functional public evidence status

- [AlphaDroid functional public evidence status, 2026-05-17](alphadroid-functional-public-evidence-status-2026-05-17.md)

Current result: public functional evidence was captured, but it did not prove full phone functionality, Google trust behavior, HyperOS 3 downgrade safety, or rollback feasibility. Track 2 remains no-go.
<!-- alphadroid-functional-public-evidence-status:end -->

<!-- decision-0008-public-functional-evidence-insufficient:start -->
## Decision 0008 public functional evidence is insufficient

- [Decision 0008, Public functional evidence is insufficient](../07-decisions/0008-public-functional-evidence-insufficient.md)
- [Maintainer functional evidence request](maintainer-functional-evidence-request.md)

Current result: public evidence is insufficient to prove a fully functional phone path. The next useful evidence must come from maintainer-level documentation, release notes, checksums or signatures, known bug lists, exact base firmware requirements, and credible functional reports.
<!-- decision-0008-public-functional-evidence-insufficient:end -->
