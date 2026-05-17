# Clean Stock Package Classification Runbook

This runbook is for read-only classification of Xiaomi or MIUI package candidates found during clean-stock feasibility work.

## Allowed

- Read the latest Step 27 clean-stock feasibility inventory.
- Classify Xiaomi or MIUI package candidates.
- Produce preserve-by-default, review-only cleanup candidate, and unknown review lists.
- Produce a shareable summary.

## Not allowed

- Uninstalling packages.
- Disabling packages.
- Changing package state.
- Unlocking the bootloader.
- Flashing.
- Downgrading.
- Installing DSU or GSI images.
- Relocking.

## Safety rule

The output is not an uninstall list. Every future cleanup action must be reviewed and must include a restore path before execution.
