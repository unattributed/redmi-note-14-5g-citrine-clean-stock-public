# Clean Stock Analytics Prechange Phone Baseline, 2026-05-17

## Current status

Step 32 collected a pre-change phone baseline for:

```text
com.miui.analytics
```

This is still evidence collection and planning only.

No package removal, package disablement, restore command execution, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was approved or performed.

## Evidence bundle

```text
citrine-clean-stock-analytics-prechange-phone-baseline-20260517-203647-shareable-summary.tar.gz
```

## Baseline result

```text
adb_state: device
boot_completed: yes
package_present_for_user0: yes
package_enabled_for_user0: yes
package_disabled_for_user0: no
package_path_state: present
manual_yes_count: 14
manual_no_count: 0
manual_unknown_count: 0
logcat_tail_fatal_exception_count: 0
logcat_tail_analytics_reference_count: 6
```

## Manual phone baseline

| ID | Check | Result | Note |
| --- | --- | --- | --- |
| `boot` | boot completes normally | `yes` | I don't know if the phone has rebooted recently, like in the last 10 minutes, I did not observe a reboot, but that doesn't mean a reboot didn't happen, perhaps we need to retest and tell the user in advance that to observe actions on the phone. |
| `lockscreen` | lock screen unlocks normally | `yes` | repeat of first comment |
| `touchscreen` | touchscreen works | `yes` | repeat of first comment |
| `launcher` | launcher opens | `yes` | repeat of first comment |
| `settings` | settings opens | `yes` |  |
| `phone` | phone app opens | `yes` | repeat of first comment |
| `sms` | SMS app opens | `yes` |  |
| `wifi` | Wi-Fi works or state is unchanged | `yes` |  |
| `mobile_data` | mobile data works or state is unchanged | `yes` |  |
| `camera` | camera opens | `yes` | y |
| `play_store` | Play Store opens | `yes` |  |
| `browser` | Chrome or WebView-backed browsing works | `yes` |  |
| `notifications` | notifications are not obviously broken | `yes` |  |
| `crash_dialogs` | no repeated crash dialogs are visible | `yes` |  |

## Restore-first rule

The restore command remains documented before any future removal command is considered.

Restore command, planned only:

```text
adb shell cmd package install-existing --user 0 com.miui.analytics
```

Future removal command, not approved:

```text
adb shell pm uninstall --user 0 com.miui.analytics
```

## Safety boundary

Step 32 does not approve execution of either the future removal command or the restore command.

## Current conclusion

The project now has a pre-change phone baseline for com.miui.analytics.

The next step is Step 33, a controlled one-package test gate for com.miui.analytics. Step 33 must not be executed unless this Step 32 baseline shows no manual failures and the package remains present, enabled, and restorable by plan.
