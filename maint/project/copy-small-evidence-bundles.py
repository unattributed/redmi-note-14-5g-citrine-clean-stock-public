#!/usr/bin/env python3
from datetime import datetime
from pathlib import Path
import hashlib
import shutil

ROOT = Path("/home/foo/Workspace/android-rom-dev")
SOURCE = Path("/home/foo/android-rom-dev-evidence")
DEST = ROOT / "evidence" / "bundles"
MANIFEST = ROOT / "evidence" / "manifests" / "evidence-bundles.md"
MAX_SIZE = 50 * 1024 * 1024

DEST.mkdir(parents=True, exist_ok=True)
MANIFEST.parent.mkdir(parents=True, exist_ok=True)

copied = []
skipped = []

if SOURCE.exists():
    for src in sorted(SOURCE.glob("*.tar.gz")):
        size = src.stat().st_size
        if size >= MAX_SIZE:
            skipped.append((src.name, size))
            continue
        dst = DEST / src.name
        shutil.copy2(src, dst)
        copied.append(dst)

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

lines = [
    "# Evidence Bundle Manifest",
    "",
    f"Generated: {datetime.now().astimezone().isoformat()}",
    "",
    "| SHA256 | Size bytes | Bundle |",
    "| --- | ---: | --- |",
]

for item in sorted(DEST.glob("*.tar.gz")):
    lines.append(f"| `{sha256(item)}` | {item.stat().st_size} | `{item.name}` |")

if skipped:
    lines.extend(["", "## Skipped local bundles over 50 MiB", ""])
    for name, size in skipped:
        lines.append(f"- `{name}`, {size} bytes")

MANIFEST.write_text("\n".join(lines) + "\n", encoding="utf-8")

print(f"copied evidence bundles: {len(copied)}")
print(f"skipped evidence bundles over 50 MiB: {len(skipped)}")
print(f"manifest: {MANIFEST}")
