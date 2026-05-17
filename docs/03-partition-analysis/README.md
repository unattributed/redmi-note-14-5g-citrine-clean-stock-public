# Partition Analysis

## Current status

The stock `super.img` was converted from sparse Android image format to raw format locally. Android logical partition metadata was parsed directly. Populated logical partition images were extracted and mounted read-only as EROFS.

## Populated logical partitions observed

- `system_a`
- `system_ext_a`
- `product_a`
- `vendor_a`
- `vendor_dlkm_a`
- `system_dlkm_a`
- `odm_dlkm_a`
- `mi_ext_a`

## Notes

The firmware package appears designed to restore active slot `a`, even though the live phone had previously reported slot `b`.
