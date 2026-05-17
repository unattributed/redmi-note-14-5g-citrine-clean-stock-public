# Evidence Index

This folder indexes committed evidence bundles under:

```text
evidence/bundles/
```

## Policy

This is a private repository. Small sanitized evidence bundles may be committed for traceability when they are intentionally generated as shareable summaries and do not contain sensitive identifiers.

Do not commit:

- multi-GB stock firmware archives,
- extracted `.img` files,
- raw `super.raw.img`,
- private evidence directories,
- full private log archives,
- full getprop output,
- full fastboot getvar output,
- serial numbers, IMEI values, Wi-Fi MAC addresses, Bluetooth MAC addresses, SIM identifiers, or account identifiers,
- cloned Android source trees,
- cloned kernel source trees.

## Committed evidence manifest

```text
evidence/manifests/evidence-bundles.md
```

## Local evidence sources

Private and large evidence stays outside Git, commonly under:

```text
/home/foo/android-rom-dev-evidence
/home/foo/android-rom-dev-private-evidence
```
