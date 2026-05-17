# Clean Stock Remaining Visible Optional OEM Cleanup, 2026-05-17

## Current status

Step 46 removed remaining launcher-visible optional OEM applications after the Step 43 launcher inventory filter was found to be too strict.

The earlier filter incorrectly reported zero launcher-visible OEM-looking packages because it did not match package names under `com.miui.*` and `com.xiaomi.*`.

## Packages removed for Android user 0

    com.miui.gallery
    com.miui.miservice
    com.xiaomi.glgm

## Package intentionally retained

    com.miui.securitycenter

## Reason Security Center was retained

Security Center is not treated as a normal optional app at this stage.

It may be tied to app permissions, app scanning, battery controls, privacy controls, and HyperOS management. Any future action against it requires a separate risk decision and restore plan.

## Direct ADB result

    adb shell pm uninstall --user 0 com.miui.gallery
    Success

    adb shell pm uninstall --user 0 com.miui.miservice
    Success

    adb shell pm uninstall --user 0 com.xiaomi.glgm
    Success

## Corrected launcher-visible OEM-looking result after Step 46

    com.miui.securitycenter

## Restore commands

    adb shell cmd package install-existing --user 0 com.miui.gallery
    adb shell cmd package install-existing --user 0 com.miui.miservice
    adb shell cmd package install-existing --user 0 com.xiaomi.glgm

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package data clearing, app force-stop, or system image modification was performed.

## Current conclusion

All remaining launcher-visible optional OEM packages found by the corrected filter were removed for Android user 0, except `com.miui.securitycenter`, which is intentionally retained for separate review.
