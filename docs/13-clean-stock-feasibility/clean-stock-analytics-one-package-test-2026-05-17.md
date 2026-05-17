# Clean Stock Analytics One-Package Test, 2026-05-17

## Current status

Step 33 executed the approved one-package user 0 test for:

```text
com.miui.analytics
```

The test used this exact approved command:

```text
adb shell pm uninstall --user 0 com.miui.analytics
```

The restore command was documented before the package change:

```text
adb shell cmd package install-existing --user 0 com.miui.analytics
```

## Evidence bundle

```text
citrine-clean-stock-analytics-one-package-test-20260517-211553-shareable-summary.tar.gz
```

## Pre-change result

```text
pre_adb_state: device
pre_boot_completed_raw: 1
pre_boot_completed: yes
pre_package_present_for_user0: yes
pre_package_enabled_for_user0: yes
pre_package_disabled_for_user0: no
pre_package_path_state: present
pre_dumpsys_user0_installed: yes
pre_dumpsys_user0_enabled_default: yes
pre_logcat_tail_fatal_exception_count: 0
pre_logcat_tail_analytics_reference_count: 0
```

## Post-change result

```text
post_adb_state: device
post_boot_completed_raw: 1
post_boot_completed: yes
post_package_present_for_user0: no
post_package_enabled_for_user0: no
post_package_disabled_for_user0: no
post_package_path_state: unknown
post_dumpsys_user0_installed: yes
post_dumpsys_user0_enabled_default: yes
post_logcat_tail_fatal_exception_count: 0
post_logcat_tail_analytics_reference_count: 13
```

## Manual post-change checks

```text
post_manual_healthy_count: 14
post_manual_failure_count: 0
post_manual_unknown_count: 0
```

## Restore result

```text
restore_executed: no
restore_reason: not_needed

```

## Important package-state interpretation

After `pm uninstall --user 0`, `pm path com.miui.analytics` may be unavailable for the current user context. This is not treated as failure when the package is absent for Android user 0, the phone remains booted, the manual checks pass, and the restore command was already documented before removal.

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package disable, package data clearing, app force-stop, or settings mutation was approved or performed.

## Current conclusion

```text
final_result: package_removed_user0_phone_healthy
```

If the final result is `package_removed_user0_phone_healthy`, then `com.miui.analytics` was removed only for Android user 0 and the phone remained healthy after the package change.
