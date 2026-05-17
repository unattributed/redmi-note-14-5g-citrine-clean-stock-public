# Risk Register

| Risk | Status | Mitigation |
| --- | --- | --- |
| Single physical device | Active | Recovery-first workflow, no flashing without go/no-go |
| Bootloader unlock wipes data | Active, avoided | Do not unlock bootloader in current clean-stock phase |
| AVB rollback or verification failure | Active | Preserve stock firmware and AVB evidence |
| Firmware image too large for GitHub | Active | Store checksums and small sanitized evidence only |
| Evidence may contain device identifiers | Active | Keep private evidence outside Git and sanitize committed summaries |
| Xiaomi or MediaTek recovery paths may require authorization | Open | Continue offline recovery research before any destructive action |
| GSI may boot partially or fail | Open | Custom ROM path remains blocked pending stronger evidence |
| Public custom ROM evidence insufficient | Active | Do not unlock or flash based on current AlphaDroid/Halcyon evidence |
| User 0 package cleanup could break daily-driver behavior | Mitigated, monitoring | Restore script committed, post-reboot validation passed, daily-driver validation plan active |
| Removing or disabling Security Center could break HyperOS management | Deferred | `com.miui.securitycenter` intentionally retained pending separate risk review |
| Launcher replacement could introduce instability | Deferred | MIUI Home retained until the clean-stock state proves stable in daily use |
| Broad cleanup may overreach into framework, security, account, modem, or overlay components | Mitigated | Broad cleanup stopped at Milestone 1, future changes require observed issue tied to package |
