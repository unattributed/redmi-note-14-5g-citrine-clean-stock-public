#!/usr/bin/env python3
from pathlib import Path

ROOT = Path("/home/foo/Workspace/android-rom-dev")
GITIGNORE = ROOT / ".gitignore"
BLOCK = """
# allow curated private evidence bundles in the repository
!evidence/
!evidence/bundles/
!evidence/bundles/*.tar.gz
!evidence/manifests/
!evidence/manifests/*.md
""".strip()

current = GITIGNORE.read_text(encoding="utf-8") if GITIGNORE.exists() else ""
if "# allow curated private evidence bundles in the repository" not in current:
    if current and not current.endswith("\n"):
        current += "\n"
    current += "\n" + BLOCK + "\n"
    GITIGNORE.write_text(current, encoding="utf-8")
    print("updated .gitignore evidence allowlist")
else:
    print(".gitignore evidence allowlist already present")
