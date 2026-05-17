# Clean Stock Restore-First Test Plan Runbook

This runbook is for planning only.

## Allowed

- Review Step 27 clean-stock inventory.
- Review Step 28 package classification.
- Define package restore commands before package removal commands.
- Generate command plans without executing them.
- Preserve package safety boundaries.

## Not allowed

- Package uninstall.
- Package disablement.
- Bootloader unlock.
- Flashing.
- Downgrade.
- DSU installation.
- GSI installation.
- Custom ROM installation.
- Rooting.
- Relock.
- Xiaomi flash script execution.

## Restore-first principle

No package-removal command should be executed unless a restore command has already been generated and reviewed.

Restore command pattern:

```text
adb shell cmd package install-existing --user 0 PACKAGE_NAME
```

Future removal command pattern, only after approval:

```text
adb shell pm uninstall --user 0 PACKAGE_NAME
```

## First candidate review set

The first candidate review set should stay small:

```text
com.miui.analytics
com.miui.msa.global
com.xiaomi.mipicks
com.xiaomi.discover
```

These packages still require package-specific review before any change.

## Current rule

Generate a plan first. Execute nothing.
