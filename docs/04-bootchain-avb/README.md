# Boot Chain and AVB

## Current status

Boot-chain images were inspected offline:

- `boot.img`
- `init_boot.img`
- `vendor_boot.img`
- `dtbo.img`
- `vbmeta.img`
- `vbmeta_system.img`
- `vbmeta_vendor.img`

AVB metadata was analyzed with AOSP `avbtool`.

## Current conclusion

The stock firmware uses a normal AVB chain with `vbmeta.img` chaining or verifying boot-chain and logical partitions.

## Rule

Do not disable verification, flash modified vbmeta, or alter boot-chain images until a written go/no-go record approves that action.
