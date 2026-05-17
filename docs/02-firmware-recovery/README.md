# Firmware Recovery

## Current status

A stock fastboot firmware package has been obtained and locally analyzed.

## Local artifact policy

Do not commit:

- stock firmware archives
- extracted stock firmware directories
- raw `super.raw.img`
- logical partition `.img` files
- preloader or boot-chain binary images

Commit only:

- checksums
- small extraction logs
- file inventories
- recovery notes
- decision records

## Recovery rule

Do not run Xiaomi `flash_all*.sh` scripts until a formal go/no-go decision exists.
