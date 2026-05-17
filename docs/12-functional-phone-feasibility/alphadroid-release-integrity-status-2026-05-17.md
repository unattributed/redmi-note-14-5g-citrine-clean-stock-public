# AlphaDroid Release Integrity Status, 2026-05-17

## Current status

Step 25 collected read-only release integrity evidence for the current AlphaDroid `beryl` / `citrine` candidate.

Evidence bundle:

```text
citrine-alphadroid-release-integrity-20260517-183631.tar.gz
```

## What was confirmed

The public SourceForge release metadata confirms these candidate artifacts exist:

- `AlphaDroid-16-20260423-gapps-beryl-v4.4.zip`
- `AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip`
- `vendor_boot.img`

The collector captured public page metadata and HEAD-only artifact metadata without downloading ROM ZIP contents or image bodies.

## Artifact HTTP metadata

### GApps build

- Artifact: `AlphaDroid-16-20260423-gapps-beryl-v4.4.zip`
- HTTP result: `200 OK`
- Content type: `application/octet-stream`
- Content length: `2488312508`
- Last modified: `Thu, 23 Apr 2026 17:08:17 GMT`
- ETag: `"69ea5201-9450a2bc"`

### Vanilla build

- Artifact: `AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip`
- HTTP result: `200 OK`
- Content type: `application/octet-stream`
- Content length: `1667461634`
- Last modified: `Thu, 23 Apr 2026 17:00:41 GMT`
- ETag: `"69ea5039-63637202"`

### Vendor boot image

- Artifact: `vendor_boot.img`
- HTTP result: `200 OK`
- Content type: `application/octet-stream`
- Content length: `67108864`
- Last modified: `Thu, 23 Apr 2026 17:03:48 GMT`
- ETag: `"69ea50f4-4000000"`

## Release integrity result

Release integrity remains incomplete.

The collector found no useful public checksum or signature evidence in the checked SourceForge metadata paths:

- `sha256`: `0` keyword hits in the public source text checked.
- `sha-256`: `0` keyword hits.
- `checksum`: `0` keyword hits.
- `signature`: `0` keyword hits.
- `.sig`: `0` keyword hits.
- `.asc`: `0` keyword hits.
- Likely checksum or signature candidate files returned `404` HTML responses rather than useful checksum or signature files.

`md5` appeared in SourceForge page text, but the Step 25 evidence does not establish that a trustworthy MD5, SHA256, signature, or maintainer-signed integrity file exists for the target artifacts.

## Current interpretation

Step 25 proves that exact public artifacts are reachable and that their HTTP metadata can be captured without modifying the phone.

Step 25 does not prove:

- release integrity,
- maintainer signature validity,
- ROM content safety,
- functional phone behavior,
- Google Play Store behavior,
- Play Protect behavior,
- Play Integrity behavior,
- sensitive application behavior,
- HyperOS 3 downgrade safety,
- rollback feasibility beyond existing partial proof.

## Current conclusion

Track 2 remains no-go.

AlphaDroid remains the strongest reachable candidate lead, but it is not approved for bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.
