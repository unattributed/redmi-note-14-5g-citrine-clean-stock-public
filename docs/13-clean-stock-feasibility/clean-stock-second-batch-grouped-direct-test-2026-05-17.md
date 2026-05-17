# Clean Stock Second Batch Grouped Direct Test, 2026-05-17

## Current status

Step 39 direct executed a grouped Android user 0 removal test for the remaining non-wallpaper second-batch packages:

```text
com.xiaomi.mipicks
com.xiaomi.discover
com.miui.videoplayer
com.miui.yellowpage
```

The grouped test used direct ADB commands after the wrapper script failed before its approval gate.

## Evidence bundle

```text
citrine-clean-stock-second-batch-grouped-direct-test-20260517-215852-shareable-summary.tar.gz
```

## Commands executed

Restore commands were documented before removal:

```text
adb shell cmd package install-existing --user 0 com.xiaomi.mipicks
adb shell cmd package install-existing --user 0 com.xiaomi.discover
adb shell cmd package install-existing --user 0 com.miui.videoplayer
adb shell cmd package install-existing --user 0 com.miui.yellowpage
```

Removal commands executed:

```text
adb shell pm uninstall --user 0 com.xiaomi.mipicks
adb shell pm uninstall --user 0 com.xiaomi.discover
adb shell pm uninstall --user 0 com.miui.videoplayer
adb shell pm uninstall --user 0 com.miui.yellowpage
```

## Direct ADB result

```text
com.xiaomi.mipicks: Success
com.xiaomi.discover: Success
com.miui.videoplayer: Success
com.miui.yellowpage: Success
```

## Manual post-change checks

```text
manual_healthy_count: 14
manual_failure_count: 0
manual_unknown_count: 0
```

## Recent fatal exceptions

```text
fatal_exception_count_tail_5000: 0
```

## Restore result

```text
restore_executed: no
restore_reason: not_needed
```

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package disable, package data clearing, app force-stop, or settings mutation was approved or performed.

## Current conclusion

```text
final_result: grouped_second_batch_removed_user0_phone_healthy
```

If the final result is `grouped_second_batch_removed_user0_phone_healthy`, then all four grouped second-batch packages were removed only for Android user 0 and the phone remained healthy in observed use.
