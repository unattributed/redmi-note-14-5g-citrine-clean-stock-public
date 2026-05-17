# Clean Stock Resistant Visible OEM App Disable, 2026-05-17

## Current status

Step 42 disabled the four visible OEM applications that resisted Android user 0 uninstall with `Failure [-1000]`.

These packages were manually confirmed still visible after Step 41.

## Packages disabled for Android user 0

    com.miui.calculator
    com.miui.compass
    com.miui.notes
    com.xiaomi.scanner

## Command pattern used

    adb shell pm disable-user --user 0 PACKAGE_NAME

## Result

    Package com.miui.calculator new state: disabled-user
    Package com.miui.compass new state: disabled-user
    Package com.miui.notes new state: disabled-user
    Package com.xiaomi.scanner new state: disabled-user

## Restore commands

    adb shell pm enable --user 0 com.miui.calculator
    adb shell pm enable --user 0 com.miui.compass
    adb shell pm enable --user 0 com.miui.notes
    adb shell pm enable --user 0 com.xiaomi.scanner

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package data clearing, app force-stop, or settings mutation was performed.

This step did use Android user 0 package disablement because ordinary Android user 0 uninstall failed for these four packages.

## Current conclusion

The remaining visible OEM applications that resisted user 0 uninstall are now disabled for Android user 0.

The next useful action is visual confirmation from the app drawer that Calculator, Compass, Notes, and Scanner are gone or unavailable.
