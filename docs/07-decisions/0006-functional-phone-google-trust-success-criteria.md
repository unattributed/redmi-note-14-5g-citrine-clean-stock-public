# Decision 0006, Functional Phone and Google Trusted Application Support Are Success Criteria

## Context

The project goal is not merely to boot a generic Android image.

A booting image that lacks drivers, vendor support, modem behavior, camera support, working sensors, reliable power management, or trusted application support is not a successful outcome for this project.

The target outcome is closer to a clean Pixel-like Android experience than to an experimental bring-up image.

## Source basis

Android Treble and GSI documentation describe a Generic System Image as a generic AOSP system image used to validate vendor interface behavior. A GSI can be useful for testing whether vendor interfaces are implemented correctly, but a GSI boot is not proof that a phone is suitable as a complete daily-driver replacement.

Google Play certification guidance states that Play Protect certified devices have passed Android compatibility testing and are eligible to include licensed Google apps such as the Google Play Store. This means a custom or unofficial image must not be assumed to provide fully trusted Google Play behavior unless the certification, licensing, and compatibility implications are understood.

Google Pixel factory image documentation is specific to restoring supported Pixel or Nexus devices to factory firmware. A Pixel image is not a transferable replacement image for the Redmi Note 14 5G `citrine` device.

## Decision

Treat a fully usable phone as the success criterion.

Do not treat any of the following as success by itself:

- Booting a GSI.
- Booting AOSP with missing hardware support.
- Booting an image without reliable cellular behavior.
- Booting an image without trusted Google Play Store behavior.
- Booting an image that requires unsafe, unclear, or unsupported Google application workarounds.
- Booting an image that cannot be rolled back safely.

## Required success properties

A future replacement image must credibly support all of the following before it can be considered a successful direction.

### Functional phone requirements

- Cellular voice and data.
- 4G or 5G behavior appropriate for the device and region.
- SIM detection and mobile network registration.
- IMS-related behavior where required by carrier use, such as VoLTE or VoWiFi.
- Wi-Fi.
- Bluetooth.
- GNSS/location.
- Front and rear cameras.
- Video recording.
- Microphone and speaker audio.
- Earpiece audio.
- Touchscreen and display brightness.
- Fingerprint or biometric behavior, if retained.
- Sensors such as accelerometer, proximity, gyroscope, and light sensor.
- USB data and charging behavior.
- Battery, thermal, suspend, and power management.
- Stable reboot and shutdown behavior.

### Google trusted application requirements

- Google Play Store access is available through a legitimate and supportable path.
- Application install behavior is compatible with normal Google Play usage.
- Play Protect or device certification implications are understood and documented.
- Play Integrity or app trust implications are understood and documented.
- Banking, messaging, authentication, and other sensitive applications are not assumed to work until tested.
- No project decision relies on unsafe or unclear Google application sideloading.

### Clean software requirements

- The software experience should be clean and minimal.
- The image should avoid unnecessary OEM, advertising, analytics, or promotional applications.
- The desired user experience is similar in spirit to a Pixel or clean AOSP-style system, but not a literal Pixel factory image.
- Required vendor components, firmware, HALs, and proprietary blobs may still be necessary for hardware functionality.

## Hard blocker

The hard blocker is the absence of a credible path to a fully functional daily-driver phone.

A custom ROM, AOSP image, Lineage-style image, or GSI path remains no-go unless it can plausibly preserve phone functionality and trusted application behavior.

## Impact

This decision shifts the project from an unlock-first mindset to a function-first feasibility mindset.

Before any bootloader unlock or permanent image replacement, the project must identify a credible path for:

- device-specific vendor support,
- driver and HAL compatibility,
- kernel and vendor image compatibility,
- Google Play Store and application trust behavior,
- rollback to stock firmware,
- and daily-driver functionality.

## Current conclusion

No-go for custom ROM flashing or permanent image replacement until functional phone feasibility is established.

Bootloader unlock remains no-go under Decision 0005 and this decision.
