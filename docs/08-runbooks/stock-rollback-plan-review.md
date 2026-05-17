# Stock Rollback Plan Review Runbook

This runbook is for review only. It does not execute rollback.

## Allowed

- Review stock firmware package availability.
- Recalculate local firmware checksums.
- Confirm the recorded fastboot baseline.
- Confirm the rollback plan exists and is understood.
- Record non-secret readiness status.

## Not allowed

- Running Xiaomi flash scripts.
- Flashing any partition.
- Unlocking the bootloader.
- Relocking the bootloader.
- Erasing userdata.
- Installing DSU or GSI images.

## Review questions

- Is the stock fastboot ROM still present locally?
- Does the local stock ROM SHA256 still match the recorded value?
- Is the rollback package for the correct device family and region?
- Is fastboot access still available?
- Is the anti-rollback value still known?
- Is the no-relock rule understood?

## Output

Update the bootloader unlock evidence worksheet only with non-secret status.
