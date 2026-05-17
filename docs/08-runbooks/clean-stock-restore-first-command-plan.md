# Clean Stock Restore-First Command Plan Runbook

This runbook supports review-only planning for clean-stock package cleanup.

## Safety boundary

This step does not execute package removal, package disablement, bootloader unlock, flashing, userdata erase, downgrade, DSU installation, custom ROM installation, root commands, or relock.

## Purpose

The command planner reads the latest Step 28 clean-stock package classification output and generates:

- first-batch candidates,
- restore commands,
- state-check commands,
- removal commands marked not approved,
- and a review-only shell plan that exits before executing package changes.

## Restore-first rule

Every candidate must have a restore command before removal is considered:

```text
adb shell cmd package install-existing --user 0 PACKAGE_NAME
```

The generated removal commands are documentation only and must not be executed until a separate approval and baseline procedure exists.

## Current conclusion

Planning is allowed. Package modification is not approved.
