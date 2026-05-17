# Clean Stock Restore-First Test Plan, 2026-05-17

## Current status

Step 28 classified Xiaomi or MIUI package candidates from the corrected Step 27 clean-stock inventory.

Current clean-stock finding:

```text
Xiaomi or MIUI packages reviewed: 102
preserve by default: 46
review-only cleanup candidates: 14
unknown, review required: 42
```

The clean-stock path is now more practical than the custom ROM path because it preserves the stock vendor image, modem stack, camera stack, Google Play Store, Google Play services, and device certification behavior while allowing controlled cleanup through Android package state changes.

## Decision for this phase

Do not remove packages yet.

Before any package is uninstalled or disabled for user `0`, the project must define a restore-first test plan.

## Scope

This plan applies only to stock HyperOS cleanup experiments using reversible Android package-management commands.

This plan does not apply to:

- bootloader unlock,
- flashing,
- downgrade,
- DSU installation,
- GSI installation,
- custom ROM installation,
- rooting,
- Magisk,
- relock,
- Xiaomi flash scripts.

## Restore-first rule

For every candidate package, the restore command must be documented before the removal command is ever run.

Preferred restore command pattern:

```text
adb shell cmd package install-existing --user 0 PACKAGE_NAME
```

Preferred package removal pattern for future testing, only after approval:

```text
adb shell pm uninstall --user 0 PACKAGE_NAME
```

Disable commands are not preferred for the first test because uninstall-for-user is usually easier to reason about and restore for user `0` using `install-existing`, provided the package still exists in the system image.

## Initial candidate pool

The Step 28 review-only cleanup candidates are:

```text
com.miui.analytics
com.miui.bugreport
com.miui.miwallpaper
com.miui.miwallpaper.config.overlay
com.miui.miwallpaper.overlay
com.miui.miwallpaper.overlay.customize
com.miui.msa.global
com.miui.thirdappassistant
com.miui.videoplayer
com.miui.wallpaper.overlay
com.miui.wallpaper.overlay.customize
com.miui.yellowpage
com.xiaomi.discover
com.xiaomi.mipicks
```

These are not yet approved for removal.

## First test batch proposal

The first future test batch should be small and low risk.

Proposed first review candidates:

```text
com.miui.analytics
com.miui.msa.global
com.xiaomi.mipicks
com.xiaomi.discover
```

Reasoning:

- They appear more likely to be promotional, analytics, advertisement, app recommendation, or discovery related.
- They are less likely to be modem, camera, telephony, IMS, Play Store, Play Services, WebView, launcher, permission controller, system UI, package installer, settings, input, sensor, audio, location, security, or device trust components.

This is only a proposal. It is not approval to remove anything.

## Preserve-by-default rule

Never remove or disable packages in these categories without deeper proof:

- Android framework,
- System UI,
- launcher,
- settings,
- package installer,
- permission controller,
- WebView,
- Google Play Store,
- Google Play services,
- Google Services Framework,
- telephony,
- IMS,
- carrier services,
- modem or radio support,
- SIM activation,
- camera,
- audio,
- sensors,
- Bluetooth,
- Wi-Fi,
- location,
- battery,
- thermal,
- security center,
- trust service,
- Find Device,
- Xiaomi account or device binding,
- payment or identity services,
- overlays that are not understood.

## Required evidence before first removal test

Before any package is removed for user `0`, collect a baseline with:

```text
adb devices -l
adb shell pm list packages -d
adb shell pm list packages -e
adb shell cmd package list packages PACKAGE_NAME
adb shell dumpsys package PACKAGE_NAME
adb shell pm path PACKAGE_NAME
```

Also record human-observed status for:

- boot completes,
- touchscreen works,
- launcher opens,
- settings opens,
- phone app opens,
- Wi-Fi works,
- mobile data state is unchanged,
- camera opens,
- Play Store opens,
- a normal app install or update path is not broken,
- notifications are not obviously broken.

## Required evidence after each package removal

After each individual package removal, not after a whole batch, verify:

- package state changed only for the intended package,
- phone remains usable,
- launcher works,
- settings works,
- Play Store works,
- connectivity remains normal,
- camera still opens,
- no new obvious crash loop occurs,
- package can be restored using `cmd package install-existing --user 0`.

## Stop conditions

Stop immediately if any of the following occurs:

- boot instability,
- launcher instability,
- settings instability,
- Play Store failure,
- Google Play services failure,
- camera failure,
- telephony or mobile data degradation,
- repeated system crash dialogs,
- package cannot be restored,
- unexpected package changes occur.

## Current conclusion

Clean-stock path remains promising, but no cleanup action is approved yet.

The next step is to create a read-only restore-first command generator that outputs proposed remove and restore commands for the first candidate batch without executing them.
