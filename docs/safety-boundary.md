# Safety Boundary

This repository is for project control, documentation, and small reproducible scripts.

## Allowed in Git

- README files,
- sanitized design notes,
- sanitized summaries,
- small helper scripts,
- safe command transcripts without device identifiers,
- recovery strategy documents,
- GSI readiness summaries,
- clean-stock milestone documents,
- small sanitized shareable evidence bundles generated for traceability,
- future device-tree work, after it exists and is reviewed.

## Not allowed in Git

- full firmware archives,
- extracted firmware images,
- raw super images,
- logical partition images,
- full getprop output,
- full fastboot getvar all output,
- private evidence directories,
- unsanitized evidence tarballs,
- evidence bundles containing serial numbers, IMEI values, Wi-Fi MAC addresses, Bluetooth MAC addresses, SIM data, account identifiers, or private user data,
- Python virtual environments,
- AOSP or LineageOS source checkouts,
- cloned kernel source trees unless intentionally added as a submodule later.

## Device safety boundary

Do not perform any of the following unless a later decision document explicitly approves it:

- bootloader unlock,
- flashing,
- downgrade,
- userdata erase,
- DSU installation,
- Google application sideloading,
- Xiaomi flash script execution,
- relock,
- system image modification.

## Clean-stock package boundary

Clean Stock Milestone 1 is complete. Broad package cleanup is stopped.

Future package changes should only happen if a specific visible app, notification, advertisement path, service behavior, or privacy concern appears and can be tied to a specific package.

## Reason

The project is being developed on a single physical phone. The repository must stay clean, reproducible, and safe to publish later if desired.
