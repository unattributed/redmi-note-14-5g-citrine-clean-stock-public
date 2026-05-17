# Clean Stock Milestone 1, Optional OEM Launcher Cleanup, 2026-05-17

## Milestone status

The clean-stock track reached Milestone 1 with a corrected scope.

The Redmi Note 14 5G remains on stock HyperOS with the bootloader locked, while the optional user-facing Xiaomi, MIUI, and OEM launcher-visible applications identified during cleanup were removed or disabled for Android user 0.

A later corrected ADB launcher inventory found that the earlier zero-OEM launcher claim was too broad because the original filter missed `com.miui.*` and `com.xiaomi.*` package names.

The corrected final launcher state is:

    launcher_oem_looking_count: 1
    launcher_visible_cleanup_target_count: 0
    retained_launcher_visible_oem_package: com.miui.securitycenter

## Device boundary preserved

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package data clearing, app force-stop, or system image modification was performed.

## Packages removed for Android user 0

    com.miui.analytics
    com.miui.msa.global
    com.miui.thirdappassistant
    com.miui.bugreport
    com.xiaomi.mipicks
    com.xiaomi.discover
    com.miui.videoplayer
    com.miui.yellowpage
    com.mi.android.globalFileexplorer
    com.mi.appfinder
    com.mi.globalminusscreen
    com.mi.healthglobal
    com.miui.android.fashiongallery
    com.miui.cleaner
    com.miui.fm
    com.miui.fmservice
    com.miui.player
    com.xiaomi.calendar
    com.android.thememanager
    com.miui.gallery
    com.miui.miservice
    com.xiaomi.glgm

## Packages disabled for Android user 0

    com.miui.calculator
    com.miui.compass
    com.miui.notes
    com.xiaomi.scanner

## Package intentionally retained

    com.miui.securitycenter

## Reason Security Center is retained

Security Center is not treated as an optional cosmetic app.

It may be tied to app permissions, app scanning, battery controls, privacy controls, update/security warnings, and HyperOS management. Any future action against it requires a separate risk decision and restore plan.

## Restore commands, removed packages

    adb shell cmd package install-existing --user 0 com.miui.analytics
    adb shell cmd package install-existing --user 0 com.miui.msa.global
    adb shell cmd package install-existing --user 0 com.miui.thirdappassistant
    adb shell cmd package install-existing --user 0 com.miui.bugreport
    adb shell cmd package install-existing --user 0 com.xiaomi.mipicks
    adb shell cmd package install-existing --user 0 com.xiaomi.discover
    adb shell cmd package install-existing --user 0 com.miui.videoplayer
    adb shell cmd package install-existing --user 0 com.miui.yellowpage
    adb shell cmd package install-existing --user 0 com.mi.android.globalFileexplorer
    adb shell cmd package install-existing --user 0 com.mi.appfinder
    adb shell cmd package install-existing --user 0 com.mi.globalminusscreen
    adb shell cmd package install-existing --user 0 com.mi.healthglobal
    adb shell cmd package install-existing --user 0 com.miui.android.fashiongallery
    adb shell cmd package install-existing --user 0 com.miui.cleaner
    adb shell cmd package install-existing --user 0 com.miui.fm
    adb shell cmd package install-existing --user 0 com.miui.fmservice
    adb shell cmd package install-existing --user 0 com.miui.player
    adb shell cmd package install-existing --user 0 com.xiaomi.calendar
    adb shell cmd package install-existing --user 0 com.android.thememanager
    adb shell cmd package install-existing --user 0 com.miui.gallery
    adb shell cmd package install-existing --user 0 com.miui.miservice
    adb shell cmd package install-existing --user 0 com.xiaomi.glgm

## Restore commands, disabled packages

    adb shell pm enable --user 0 com.miui.calculator
    adb shell pm enable --user 0 com.miui.compass
    adb shell pm enable --user 0 com.miui.notes
    adb shell pm enable --user 0 com.xiaomi.scanner

## Intentionally retained platform components

Core phone, camera, Play Store, Play services, WebView/Chrome, launcher, settings, security, framework, account, cloud, modem, vendor, wallpaper, overlay, and device-specific support packages remain in place unless a later explicit risk decision says otherwise.

## Current decision

Stop broad package cleanup at Milestone 1.

Further cleanup should only happen if a specific visible app, service behavior, notification, advertisement path, or privacy concern is observed and tied to a specific package.
