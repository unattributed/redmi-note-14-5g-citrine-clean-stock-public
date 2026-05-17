# Maintainer Functional Evidence Request

## Purpose

This document provides a non-secret checklist for asking a ROM maintainer or trusted community source whether a candidate image can meet the project success criteria.

The goal is not to obtain private data. The goal is to determine whether a candidate ROM can produce a fully usable, clean, Google-trusted phone on Redmi Note 14 5G / POCO M7 Pro 5G `beryl` / `citrine`.

## Safety boundary

Do not include:

- Passwords.
- Account names.
- Phone numbers.
- IMEI values.
- Serial numbers.
- Recovery codes.
- Private screenshots.
- Private chat logs.
- Private build links that the maintainer did not intend to publish.

## Candidate identity questions

- What exact device variants are supported?
- Are both `beryl` and `citrine` supported?
- What exact model numbers are known working?
- What base firmware is required?
- Is HyperOS 3 supported, or is downgrade required?
- If downgrade is required, what exact target firmware is required?
- Is the downgrade path tested on the Redmi Note 14 5G / POCO M7 Pro 5G family?

## Release integrity questions

- Is there a SHA256 checksum for the GApps build?
- Is there a SHA256 checksum for the Vanilla build?
- Is there a SHA256 checksum for `vendor_boot.img`?
- Are releases signed?
- Are release notes published?
- Is there a known bug list?
- Is there a device changelog for the exact release?

## Functional phone questions

- Does cellular registration work?
- Does mobile data work?
- Is IMS behavior known?
- Is VoLTE known working or not working?
- Is VoWiFi known working or not working?
- Are emergency calling risks documented?
- Does Wi-Fi work?
- Does Bluetooth work?
- Does GNSS or location work?
- Do front and rear cameras work?
- Does video recording work?
- Does audio output work?
- Do microphones work?
- Do sensors work?
- Does USB data work?
- Does charging work?
- Are battery drain, suspend, and thermal behavior acceptable?
- Is Vulkan or GPU behavior known working or known broken?

## Google trust questions

- Is the GApps build shipped by the ROM project, or does it require a separate Google application package?
- What Google application distribution path is expected?
- Does the Play Store open and install applications normally?
- What is the Play Protect certification behavior?
- What is the Play Integrity behavior?
- Are there known sensitive application issues?
- Are banking or identity applications expected to fail?

## Clean software profile questions

- What applications are included by default?
- Is there unwanted promotional software?
- Is there ROM telemetry or analytics that should be reviewed?
- Is there an OTA update mechanism?
- Is the user experience closer to Pixel-like Android, AOSP-style Android, or a heavily customized ROM?

## Rollback questions

- What rollback path is recommended by the maintainer?
- Is return to stock fastboot firmware expected to work?
- Is relock explicitly unsafe after using non-stock images?
- Are there known brick risks on this device family?

## Current project interpretation

Until enough answers are collected, the project remains no-go for bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
