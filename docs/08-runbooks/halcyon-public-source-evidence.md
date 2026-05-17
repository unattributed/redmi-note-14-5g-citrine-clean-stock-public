# Halcyon Public Source Evidence Runbook

This runbook captures public source evidence for the Halcyon `beryl` candidate.

## Purpose

Collect source-page evidence that can support the functional phone feasibility track.

## Allowed

- Fetch public Halcyon device and supported-device pages.
- Fetch public Google documentation relevant to Play Protect, GMS, GSI, and Play Integrity.
- Extract candidate links from the Halcyon device page.
- Store evidence under `/home/foo/android-rom-dev-evidence/`.

## Not allowed

- Bootloader unlock.
- Flashing.
- Userdata erase.
- DSU installation.
- GSI installation.
- Google app sideloading.
- Xiaomi account binding.
- Phone modification.

## Output

The script writes a tarball named like:

```text
/home/foo/android-rom-dev-evidence/citrine-halcyon-source-evidence-YYYYMMDD-HHMMSS.tar.gz
```

This evidence does not prove full phone functionality. It only improves the source-review basis.
