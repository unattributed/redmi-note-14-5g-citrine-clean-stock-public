# Clean Stock Google Default Role Validation, 2026-05-17

## Current status

Step 49 validated Google-oriented default app behavior after the clean-stock package cleanup.

This step did not remove packages, disable packages, clear data, force-stop apps, unlock the bootloader, flash images, wipe userdata, sideload Google applications, or modify system images.

## Confirmed installed packages

    com.google.android.dialer
    com.google.android.apps.messaging
    com.android.chrome
    com.google.android.googlequicksearchbox
    com.miui.home

## Role command correction

The device supports:

    adb shell cmd role get-role-holders --user 0 ROLE

The earlier command form `cmd role holders` is not supported on this device.

## Role service result

The role service dump showed these relevant holders for Android user 0:

    android.app.role.DIALER: com.google.android.dialer
    android.app.role.SMS: com.google.android.apps.messaging
    android.app.role.BROWSER: com.android.chrome
    android.app.role.ASSISTANT: com.google.android.googlequicksearchbox
    android.app.role.HOME: com.miui.home

## Intent resolution result

The direct intent-resolution checks confirmed:

    DIAL tel: resolves to com.google.android.dialer
    SENDTO smsto: resolves to com.google.android.apps.messaging
    VIEW https: resolves to com.android.chrome
    HOME resolves to com.miui.home

The ASSIST intent check returned Android's resolver rather than directly resolving to the Google app, even though the role service lists Google as the assistant role holder.

## Current conclusion

The phone is now closer to a Pixel-like default app model while staying on stock HyperOS.

Google Phone, Google Messages, and Chrome are confirmed as default handlers for the tested intents.

The Google app is the assistant role holder, but direct ASSIST intent behavior remains device-specific and should not be overstated.

MIUI Home remains the launcher because no replacement launcher has been installed or selected.
