# GSI Readiness

## Current status

The corrected reconnect-safe collector successfully captured live ADB, Treble, dynamic partition, Virtual A/B, AVB, and fastboot readiness evidence.

A read-only DSU readiness probe completed, followed by a read-only DSU component inspection, a read-only DSU intent resolution follow-up, an offline APK manifest inspection attempt, and an official-tool APK decode using Android SDK Build Tools.

## Confirmed live properties

- ADB authorization works.
- Fastboot access works.
- Device product is `citrine`.
- Current slot is `_b`.
- Slot count is `2`.
- Bootloader is locked.
- Secure boot is enabled.
- Anti-rollback value reported by fastboot is `1`.
- Verified boot state is `green`.
- AVB device state is `locked`.
- Verity mode is `enforcing`.
- Treble is enabled.
- Dynamic partitions are enabled.
- Virtual A/B is enabled.
- Virtual A/B compression is enabled.
- CPU ABI is `arm64-v8a`.
- Maximum CPU page size property is `16384`.

## DSU probe result

DSU backend components are present:

- `com.android.dynsystem`
- `/system/priv-app/DynamicSystemInstallationService/DynamicSystemInstallationService.apk`
- `/system/bin/gsi_tool`
- `/system/etc/init/gsid.rc`
- `/system/lib64/gsi_aidl_interface-cpp.so`
- `/system/lib64/libgsi.so`

The initial public install activity probe did not resolve:

- `android.os.image.action.START_INSTALL`
- `android.settings.DYNAMIC_SYSTEM_SETTINGS`
- `com.android.dynsystem.action.START_INSTALL`

## DSU component inspection result

The deeper component inspection shows that DSU support is more complete than the first probe suggested:

- `com.android.dynsystem` is installed as a privileged system app.
- `com.android.dynsystem/.VerificationActivity` declares `android.os.image.action.START_INSTALL` intent filters.
- The package requests privileged DSU permissions, including `MANAGE_DYNAMIC_SYSTEM` and `INSTALL_DYNAMIC_SYSTEM`.
- The Android service list included DSU-related binder services during component inspection.
- A `gsid` process was visible.
- `/system/bin/gsi_tool` exists and reports supported commands including `install`, `enable`, `disable`, `wipe`, `wipe-data`, `cancel`, and `status`.

The component inspection summary has one known script-level interpretation defect: it reports `dynsystem_package_present: no`, but the raw package evidence shows `com.android.dynsystem` is present. Treat the raw package evidence as authoritative.

## DSU intent resolution follow-up result

The intent follow-up confirmed:

- ADB was ready.
- `com.android.dynsystem/.VerificationActivity` appears in the package resolver table.
- `VerificationActivity` declares `android.os.image.action.START_INSTALL` with `android.intent.category.DEFAULT`.
- It declares scheme filters for `content`, `file`, `http`, and `https`.
- Shell resolver checks still returned `No activity found` for the action-only, DEFAULT-category, and dummy URI variants.
- `cmd package query-intent-activities` is not available on this build.
- `/system/bin/gsi_tool status` returned `normal`.
- `gsid` was running according to process and property evidence.

## Manual Developer Options UI check

The manual Developer Options check found that `DSU Loader` or `Dynamic System Updates` was not visible in Developer Options.

The earlier visibility observation was committed in error and corrected by a later clarification commit.

## Offline APK manifest inspection result

The APK was pulled from read-only `/system` for offline inspection:

- Device path: `/system/priv-app/DynamicSystemInstallationService/DynamicSystemInstallationService.apk`
- APK SHA256: `a9b43e9b357a15897ef3674975a61b35b2f06ccc4239b60a00bf869248c311c2`

The initial self-contained manifest parser did not correctly decode this APK manifest. Its output said `VerificationActivity: not found`, but `dumpsys package com.android.dynsystem` and APK string evidence showed `VerificationActivity`, `android.os.image.action.START_INSTALL`, `DynamicSystemInstallationService`, and DSU installation strings.

## Official-tool APK decode result

Android SDK Command-Line Tools and Build Tools were installed locally under `/home/foo/Android/Sdk`.

The successful official-tool decode confirmed:

- `aapt2` is present at `/home/foo/Android/Sdk/build-tools/36.0.0/aapt2`.
- `aapt` is present at `/home/foo/Android/Sdk/build-tools/36.0.0/aapt`.
- `apkanalyzer` is present at `/home/foo/Android/Sdk/cmdline-tools/latest/bin/apkanalyzer`.
- The APK SHA256 remains `a9b43e9b357a15897ef3674975a61b35b2f06ccc4239b60a00bf869248c311c2`.
- `com.android.dynsystem/.DynamicSystemInstallationService` is exported and protected by `android.permission.INSTALL_DYNAMIC_SYSTEM`.
- `com.android.dynsystem/.VerificationActivity` is exported and protected by `android.permission.INSTALL_DYNAMIC_SYSTEM`.
- `VerificationActivity` declares `android.os.image.action.START_INSTALL`.
- `VerificationActivity` declares `android.intent.category.DEFAULT`.
- `VerificationActivity` declares data schemes for `content`, `file`, `http`, and `https`.
- The APK uses privileged DSU-related permissions including `android.permission.MANAGE_DYNAMIC_SYSTEM`, `android.permission.REBOOT`, and `android.permission.READ_OEM_UNLOCK_STATE`.

## Current interpretation

The device remains a reasonable GSI-readiness candidate from a platform perspective.

The stock HyperOS user build contains real DSU backend components, a privileged DSU package, exported DSU service and verification components, and a valid DSU `START_INSTALL` activity declaration.

However, the normal public path is not available to the user in Developer Options, and shell resolution still failed. The strongest explanation is that the DSU route is present but permission-gated by `android.permission.INSTALL_DYNAMIC_SYSTEM`, OEM-hidden, or otherwise not exposed for normal user interaction on this build.

This supports a decision that DSU should not be attempted without a separate go/no-go record. The next safe planning step is a bootloader unlock go/no-go analysis, not unlocking.

## Still needed

- Write a decision record that DSU is present but not exposed as a safe user-accessible path on this stock build.
- Prepare a bootloader unlock go/no-go decision record.
- Confirm the official Xiaomi unlock procedure, wait requirements, data wipe impact, and rollback process.
- Do not start the DSU activity, pass image URLs, install DSU, or use `gsi_tool install` without a separate go/no-go record.
- Do not unlock the bootloader without a separate go/no-go record.

## Current rule

No DSU installation yet.
No GSI flash testing yet.
No bootloader unlock yet.
No Xiaomi `flash_all*.sh` execution yet.
