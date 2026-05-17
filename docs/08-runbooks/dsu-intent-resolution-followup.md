# DSU Intent Resolution Follow-up Runbook

This runbook is for read-only investigation only.

## Purpose

The first DSU readiness probe found DSU backend components but did not resolve the public install activity. The component inspection later showed that `com.android.dynsystem/.VerificationActivity` declares `android.os.image.action.START_INSTALL` intent filters.

The next probe should determine whether the earlier negative activity resolution was a false negative caused by missing resolver parameters.

## Allowed

- ADB read-only package resolver queries.
- ADB read-only package dumps.
- `gsi_tool status` only.
- Checking service lists and process status.

## Not allowed

- Starting the DSU install activity.
- Passing real image URLs or real image files to DSU.
- `gsi_tool install`.
- `gsi_tool enable`.
- `gsi_tool wipe`.
- `gsi_tool wipe-data`.
- Bootloader unlock.
- Flashing.
- Persistent settings changes.

## Evidence to collect later

- Resolver queries with `android.intent.category.DEFAULT`.
- Resolver queries with safe dummy URI schemes.
- Package dump sections around `VerificationActivity`.
- `gsi_tool status` output.
- `service list` entries for `dynamic_system` and `gsiservice`.
- `ps -A` entries for `gsid`.
