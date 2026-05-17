# Clean Stock Feasibility

This folder tracks the clean-stock path for the Redmi Note 14 5G `citrine` project.

The clean-stock path keeps the stock HyperOS base, vendor drivers, modem behavior, camera support, Google Play Store, Google Play Services, verified boot state, locked bootloader, and return-to-stock posture while reducing unwanted OEM applications through Android user 0 package management.

This path is separate from the custom ROM track.

## Current status

Clean Stock Milestone 1 is complete and validated as a daily-driver candidate.

Current result:

- stock HyperOS retained,
- bootloader locked,
- no flashing,
- no downgrade,
- no userdata erase,
- no DSU installation,
- no Google application sideloading,
- no Xiaomi flash script execution,
- no relock,
- optional user-facing OEM launcher applications removed or disabled for Android user 0,
- `com.miui.securitycenter` intentionally retained,
- Google Phone, Google Messages, and Chrome validated as default handlers,
- Google app recorded as assistant role holder,
- MIUI Home retained for stability,
- post-reboot normal phone functions confirmed working,
- restore script committed.

## Current stop condition

Do not remove, disable, or change additional packages unless a specific visible app, notification, advertisement path, service behavior, or privacy concern appears and can be tied to a specific package.

## Current milestone documents

- [Corrected Milestone 1 summary](clean-stock-milestone-1-zero-visible-oem-launcher-2026-05-17.md)
- [Post-reboot functional validation](clean-stock-post-reboot-functional-validation-2026-05-17.md)
- [Google default role validation](clean-stock-google-default-role-validation-2026-05-17.md)
- [Launcher decision](clean-stock-launcher-decision-2026-05-17.md)
- [Daily-driver validation plan](clean-stock-daily-driver-validation-plan-2026-05-17.md)

## Current tools

```text
scripts/step43-adb-visible-launcher-inventory.sh
scripts/restore-clean-stock-milestone1-user0.sh
```

Use the inventory script for read-only launcher and package-state checks.

Use the restore script only if Milestone 1 needs to be reverted:

```text
scripts/restore-clean-stock-milestone1-user0.sh --dry-run
scripts/restore-clean-stock-milestone1-user0.sh --execute
```

## Historical note

Earlier files in this folder record the project state at the time they were created. Some early documents correctly say package removal was not yet approved at that earlier step. Those files are retained as engineering history.

The current controlling state is the corrected Milestone 1 summary, post-reboot validation, Google default-role validation, launcher decision, daily-driver validation plan, and restore script.
