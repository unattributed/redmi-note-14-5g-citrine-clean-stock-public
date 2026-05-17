# Clean Stock Optional OEM App Cleanup, 2026-05-17

## Current status

Step 41 directly removed optional user-facing Xiaomi and MIUI applications from Android user 0.

This step did not send APKs, files, user data, or replacement software to the phone. It changed Android user 0 package registration with:

    adb shell pm uninstall --user 0 PACKAGE_NAME

## Packages removed for Android user 0

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

## Packages not removed

The following packages returned Failure [-1000] and remained present for Android user 0.

Manual checking confirmed they were not removed:

    com.miui.calculator
    com.miui.compass
    com.miui.notes
    com.xiaomi.scanner

## Restore commands for removed packages

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

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package disable, package data clearing, app force-stop, or settings mutation was performed.

## Current conclusion

The clean-stock path has removed the main optional user-facing OEM applications that accepted Android user 0 removal.

The four Failure [-1000] packages are confirmed still present and should not be forced at this stage. Further action on those packages would require a separate risk decision because it would likely involve package disablement or deeper Android package state changes rather than ordinary user 0 uninstall.
