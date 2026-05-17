# Clean Stock ADB Visible Launcher Inventory, 2026-05-17

## Current status

Step 43 used ADB package-manager inventory instead of manual screenshot review to identify launcher-visible packages after clean-stock cleanup.

## Summary

    launcher_package_count: 108
    launcher_oem_looking_count: 1
    disabled_cleanup_target_count: 4
    launcher_visible_cleanup_target_count: 0

## Cleanup target result

All previously removed or disabled cleanup targets are no longer launcher-visible.

The four resistant applications remain installed but are disabled for Android user 0:

    com.miui.calculator
    com.miui.compass
    com.miui.notes
    com.xiaomi.scanner

## Remaining launcher-visible OEM-looking package

    com.android.thememanager

This appears to be the remaining visible OEM Themes application.

## Current decision

The main clean-stock target has been reached for the previously identified user-facing OEM applications.

The only remaining visible OEM-looking launcher package is com.android.thememanager. Further action on it should be handled as a separate UI/theming decision because it may affect wallpapers, themes, icons, and lock-screen appearance.

## Restore commands for disabled resistant apps

    adb shell pm enable --user 0 com.miui.calculator
    adb shell pm enable --user 0 com.miui.compass
    adb shell pm enable --user 0 com.miui.notes
    adb shell pm enable --user 0 com.xiaomi.scanner
