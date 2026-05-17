# Clean Stock Analytics Baseline and Restore Plan, 2026-05-17

## Current status

Step 31 collected a one-package baseline and restore planning record for:

```text
com.miui.analytics
```

This is still planning and evidence collection only.

No package removal, package disablement, restore command execution, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was approved or performed.

## Evidence bundle

```text
citrine-clean-stock-analytics-baseline-restore-plan-20260517-203015-shareable-summary.tar.gz
```

## Baseline result

```text
package_present_for_user0: yes
package_enabled_for_user0: yes
package_disabled_for_user0: no
package_path_state: present
```

## Restore-first rule

The restore command exists before any future removal command is considered.

Restore command, planned only:

```text
adb shell cmd package install-existing --user 0 com.miui.analytics
```

Future removal command, not approved:

```text
adb shell pm uninstall --user 0 com.miui.analytics
```

## Required human baseline before any future package change

Before any future package modification, record that these still work:

- boot completes normally,
- lock screen unlocks normally,
- touchscreen works,
- launcher opens,
- settings opens,
- phone app opens,
- SMS app opens,
- Wi-Fi state is unchanged,
- mobile data state is unchanged,
- camera opens,
- Play Store opens,
- Chrome or WebView-backed browsing works,
- notifications are not obviously broken,
- no repeated crash dialogs are visible.

## Safety boundary

Step 31 does not approve execution of either the future removal command or the restore command.

## Current conclusion

Clean-stock cleanup remains promising, but the project is still in restore-first planning.

The next step may only consider a single-package test for com.miui.analytics if explicitly approved.
