# Clean Stock Theme Manager User 0 Uninstall, 2026-05-17

## Current status

Step 45 removed the remaining launcher-visible OEM Themes application from Android user 0.

The previous disable attempt failed safely with:

    java.lang.SecurityException: Cannot disable system packages.

The ordinary Android user 0 uninstall succeeded:

    adb shell pm uninstall --user 0 com.android.thememanager
    Success

## Verification

ADB device verification showed the connected target was the Redmi Note 14 5G citrine device:

    product:citrine_global
    model:24094RAD4G
    device:citrine

After uninstall, package queries no longer showed the main Theme Manager package for Android user 0.

Only the related overlay package remained:

    com.android.thememanager.customizethemeconfig.config.overlay

The launcher-visible OEM-looking package query returned no results.

## Restore command

    adb shell cmd package install-existing --user 0 com.android.thememanager

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package data clearing, app force-stop, or settings mutation was performed.

## Current conclusion

The clean-stock launcher-visible OEM cleanup milestone is reached.

No launcher-visible OEM-looking packages were returned by the ADB launcher inventory query after removing Theme Manager for Android user 0.
