# Clean Stock Second Batch Restore-First Command Plan, 2026-05-17

## Current status

Step 37 generated a restore-first command plan for the next clean-stock review-only candidate group.

This is command planning only.

Step 37 did not execute uninstall, restore, disable, package data clearing, force-stop, settings mutation, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Evidence bundle

```text
citrine-clean-stock-second-batch-command-plan-20260517-213607-shareable-summary.tar.gz
```

## Device state

```text
adb_state: device
boot_completed_raw: 1
boot_completed: yes
fatal_exception_count_tail_5000: 0
```

## First batch retained state

The first batch remains absent for Android user 0.

```text
package                     present_user0  enabled_user0  disabled_user0  path_state  restore_command
com.miui.analytics          no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.analytics
com.miui.msa.global         no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.msa.global
com.miui.thirdappassistant  no             no             no              unknown     adb shell cmd package install-existing --user 0 com.miui.thirdappassistant
```

## Remaining review-only candidates checked

```text
package                                 present_user0  enabled_user0  disabled_user0  path_state  restore_command                                                                         future_removal_command_not_approved
com.miui.bugreport                      yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.bugreport                      adb shell pm uninstall --user 0 com.miui.bugreport
com.miui.miwallpaper                    yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.miwallpaper                    adb shell pm uninstall --user 0 com.miui.miwallpaper
com.miui.miwallpaper.config.overlay     yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.miwallpaper.config.overlay     adb shell pm uninstall --user 0 com.miui.miwallpaper.config.overlay
com.miui.miwallpaper.overlay            yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.miwallpaper.overlay            adb shell pm uninstall --user 0 com.miui.miwallpaper.overlay
com.miui.miwallpaper.overlay.customize  yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.miwallpaper.overlay.customize  adb shell pm uninstall --user 0 com.miui.miwallpaper.overlay.customize
com.miui.videoplayer                    yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.videoplayer                    adb shell pm uninstall --user 0 com.miui.videoplayer
com.miui.wallpaper.overlay              yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.wallpaper.overlay              adb shell pm uninstall --user 0 com.miui.wallpaper.overlay
com.miui.wallpaper.overlay.customize    yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.wallpaper.overlay.customize    adb shell pm uninstall --user 0 com.miui.wallpaper.overlay.customize
com.miui.yellowpage                     yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.yellowpage                     adb shell pm uninstall --user 0 com.miui.yellowpage
com.xiaomi.discover                     yes            yes            no              present     adb shell cmd package install-existing --user 0 com.xiaomi.discover                     adb shell pm uninstall --user 0 com.xiaomi.discover
com.xiaomi.mipicks                      yes            yes            no              present     adb shell cmd package install-existing --user 0 com.xiaomi.mipicks                      adb shell pm uninstall --user 0 com.xiaomi.mipicks
```

## Second batch command plan

The second batch order is intentionally focused on non-wallpaper review-only candidates first.

```text
order  package               present_user0  enabled_user0  disabled_user0  path_state  restore_command                                                       future_removal_command_not_approved
1      com.miui.bugreport    yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.bugreport    adb shell pm uninstall --user 0 com.miui.bugreport
2      com.xiaomi.mipicks    yes            yes            no              present     adb shell cmd package install-existing --user 0 com.xiaomi.mipicks    adb shell pm uninstall --user 0 com.xiaomi.mipicks
3      com.xiaomi.discover   yes            yes            no              present     adb shell cmd package install-existing --user 0 com.xiaomi.discover   adb shell pm uninstall --user 0 com.xiaomi.discover
4      com.miui.videoplayer  yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.videoplayer  adb shell pm uninstall --user 0 com.miui.videoplayer
5      com.miui.yellowpage   yes            yes            no              present     adb shell cmd package install-existing --user 0 com.miui.yellowpage   adb shell pm uninstall --user 0 com.miui.yellowpage
```

## Deferred review candidates

```text
package                                 reason
com.miui.miwallpaper                    deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
com.miui.miwallpaper.config.overlay     deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
com.miui.miwallpaper.overlay            deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
com.miui.miwallpaper.overlay.customize  deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
com.miui.wallpaper.overlay              deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
com.miui.wallpaper.overlay.customize    deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates
```

## Restore-first rule

Every planned second-batch package has a restore command documented before any future removal command is considered.

Restore pattern:

```text
adb shell cmd package install-existing --user 0 PACKAGE_NAME
```

Removal pattern, not approved by Step 37:

```text
adb shell pm uninstall --user 0 PACKAGE_NAME
```

## Safety boundary

The generated second-batch commands are not approved for execution by this step.

Future execution must continue one package at a time, with explicit approval and post-change phone checks.

## Current conclusion

```text
final_result: second_batch_restore_first_plan_ready
```

If the final result is `second_batch_restore_first_plan_ready`, the next package test may proceed with the first planned second-batch package only.
