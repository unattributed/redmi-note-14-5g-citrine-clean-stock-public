# Clean Stock First Batch Post-Change Baseline, 2026-05-17

## Current status

Step 36 collected a read-only post-change baseline after the first clean-stock package batch.

The first batch packages are:

```text
com.miui.analytics
com.miui.msa.global
com.miui.thirdappassistant
```

Step 36 did not execute uninstall, restore, disable, package data clearing, force-stop, settings mutation, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Evidence bundle

```text
citrine-clean-stock-first-batch-postchange-baseline-20260517-212929-shareable-summary.tar.gz
```

## Device state

```text
adb_state: device
boot_completed_raw: 1
boot_completed: yes
fatal_exception_count_tail_5000: 0
```

## First batch package state

```text
package                     present_user0  enabled_user0  disabled_user0  path_state  restore_command
com.miui.analytics          no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.analytics
com.miui.msa.global         no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.msa.global
com.miui.thirdappassistant  no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.thirdappassistant
```

## Manual post-batch checks

```text
manual_healthy_count: 14
manual_failure_count: 0
manual_unknown_count: 0
```

## Restore commands remain available

```text
adb shell cmd package install-existing --user 0 com.miui.analytics
adb shell cmd package install-existing --user 0 com.miui.msa.global
adb shell cmd package install-existing --user 0 com.miui.thirdappassistant
```

## Safety boundary

This step is validation only. It records the state after the first batch, but does not approve a second cleanup batch by itself.

## Current conclusion

```text
final_result: first_batch_removed_user0_phone_healthy
```

If the final result is `first_batch_removed_user0_phone_healthy`, then all three first-batch packages are absent for Android user 0 and the phone remains healthy in observed use.
