#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "== staged files =="
git diff --cached --name-only

echo
echo "== large staged files check, over 50 MiB =="
git diff --cached --name-only | while read -r f; do
  [ -f "$f" ] || continue
  size="$(stat -c '%s' "$f")"
  if [ "$size" -gt 52428800 ]; then
    echo "large staged file over 50 MiB: $size $f"
  fi
done

echo
echo "== forbidden staged filename check =="
git diff --cached --name-only   | grep -Ei 'firmware/.+\.(img|bin|auth|tgz|zip|7z|xz|lz4|br)$|super\.raw\.img|source/xiaomi-beryl|payload-dumper-venv|\.repo/' || true
