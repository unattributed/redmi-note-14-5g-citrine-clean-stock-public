# DSU Manual UI Check Runbook

This runbook is for manual observation only. It does not install DSU, start a DSU activity, flash, unlock, or modify the phone.

## Purpose

Determine whether the stock HyperOS Developer Options UI exposes DSU Loader even though shell resolver checks did not confirm a public install path.

## Allowed

- Open Android Settings manually.
- Search Developer Options for DSU Loader or Dynamic System Updates.
- Record whether the UI entry exists.
- Do not select an image.
- Do not start installation.

## Not allowed

- DSU installation.
- Selecting a GSI image.
- Passing image URLs.
- Running `gsi_tool install`, `enable`, `wipe`, or `wipe-data`.
- Bootloader unlock.
- Flashing.
- Persistent settings changes.

## Procedure

1. Keep the phone booted normally.
2. Open Settings.
3. Open Additional settings.
4. Open Developer options.
5. Search visually for DSU Loader, Dynamic System Updates, or a similar entry.
6. Record only whether the entry is visible.
7. Do not tap through any install workflow.

## Result format

Record the observation in `docs/05-gsi-readiness/README.md` and, if screenshots are taken, keep them private until sanitized.
