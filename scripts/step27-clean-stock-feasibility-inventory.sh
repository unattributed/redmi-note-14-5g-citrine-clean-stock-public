#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
PRIVATE_ROOT="/home/foo/android-rom-dev-private-backups/clean-stock-feasibility"
RUN_ID="citrine-clean-stock-feasibility-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${PRIVATE_ROOT}/${RUN_ID}"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-adb" \
         "${OUT_DIR}/02-packages-private" \
         "${OUT_DIR}/03-shareable-summary"

log() {
  printf '%s\n' "$*"
}

run_capture() {
  local out_file="$1"
  shift
  {
    echo "command: $*"
    echo "timestamp: $(date -Is)"
    echo
    "$@" 2>&1 || true
  } > "${out_file}"
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
clean stock feasibility inventory
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
out_dir: ${OUT_DIR}

purpose:
- evaluate whether stock HyperOS can be cleaned through controlled ADB package management
- preserve functional phone behavior
- preserve Google Play Store and Google services behavior
- avoid destructive bootloader or flashing paths

safety:
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no package uninstall
- no package disable
- read-only ADB inventory only

privacy:
- full package inventory stays in this private local directory
- shareable summary excludes third-party package names
CTX

run_capture "${OUT_DIR}/00-context/host-baseline.txt" bash -c '
cat /etc/os-release 2>/dev/null || true
echo
uname -a
echo
for tool in adb python3 tar sha256sum grep sed awk; do
  printf "%-12s " "${tool}:"
  command -v "${tool}" || true
done
echo
adb version 2>&1 || true
'

log "clean stock feasibility inventory"
log "timestamp: $(date -Is)"
log "out_dir: ${OUT_DIR}"
log ""
log "waiting for adb device"

adb start-server >/dev/null 2>&1 || true

ADB_READY="no"
for attempt in $(seq 1 24); do
  if adb devices 2>/dev/null | awk '$2 == "device" {found=1} END {exit found ? 0 : 1}'; then
    ADB_READY="yes"
    break
  fi
  sleep 5
done

{
  echo "adb_ready=${ADB_READY}"
  echo
  adb devices -l 2>&1 || true
} > "${OUT_DIR}/01-adb/adb-devices.txt"

if [ "${ADB_READY}" != "yes" ]; then
  echo "ADB device not ready. Unlock the phone screen, approve USB debugging, then rerun."
  exit 1
fi

run_capture "${OUT_DIR}/01-adb/device-state.txt" adb shell '
echo "== selected properties =="
for prop in \
  ro.product.marketname \
  ro.product.model \
  ro.product.device \
  ro.product.board \
  ro.board.platform \
  ro.build.version.release \
  ro.build.version.sdk \
  ro.build.version.security_patch \
  ro.boot.verifiedbootstate \
  ro.boot.vbmeta.device_state \
  ro.boot.flash.locked \
  ro.boot.veritymode
do
  echo "${prop}=$(getprop "${prop}")"
done
echo
echo "== current user =="
am get-current-user 2>/dev/null || true
cmd user list 2>/dev/null || true
'

run_capture "${OUT_DIR}/02-packages-private/packages-all.txt" adb shell 'pm list packages -f -U -i'
run_capture "${OUT_DIR}/02-packages-private/packages-system.txt" adb shell 'pm list packages -s -f -U -i'
run_capture "${OUT_DIR}/02-packages-private/packages-third-party.txt" adb shell 'pm list packages -3 -f -U -i'
run_capture "${OUT_DIR}/02-packages-private/packages-disabled.txt" adb shell 'pm list packages -d -f -U -i'
run_capture "${OUT_DIR}/02-packages-private/packages-enabled.txt" adb shell 'pm list packages -e -f -U -i'
run_capture "${OUT_DIR}/02-packages-private/features.txt" adb shell 'pm list features'
run_capture "${OUT_DIR}/02-packages-private/selected-google-packages.txt" adb shell '
for pkg in \
  com.android.vending \
  com.google.android.gms \
  com.google.android.gsf \
  com.google.android.apps.restore \
  com.google.android.partnersetup \
  com.google.android.printservice.recommendation \
  com.google.android.tts \
  com.google.android.webview \
  com.android.chrome
do
  echo "## ${pkg}"
  pm path "${pkg}" 2>&1 || true
  dumpsys package "${pkg}" 2>/dev/null | grep -E "Package \\[|versionName=|versionCode=|installerPackageName=|enabled=|hidden=" | head -n 40 || true
  echo
done
'

OUT_DIR="${OUT_DIR}" python3 - <<'PY'
from pathlib import Path
import os
import re

root = Path(os.environ["OUT_DIR"])
private_dir = root / "02-packages-private"
summary_dir = root / "03-shareable-summary"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""


def extract_packages(text: str) -> list[str]:
    packages: set[str] = set()
    for raw in text.splitlines():
        line = raw.strip()
        if not line.startswith("package:"):
            continue
        match = re.match(r"^package:.*?=([A-Za-z0-9_][A-Za-z0-9._]+)(?:\s|$)", line)
        if match:
            packages.add(match.group(1))
            continue
        match = re.match(r"^package:([A-Za-z0-9_][A-Za-z0-9._]+)(?:\s|$)", line)
        if match:
            packages.add(match.group(1))
    return sorted(packages)

all_text = read(private_dir / "packages-all.txt")
system_text = read(private_dir / "packages-system.txt")
third_text = read(private_dir / "packages-third-party.txt")
disabled_text = read(private_dir / "packages-disabled.txt")
enabled_text = read(private_dir / "packages-enabled.txt")

all_pkgs = extract_packages(all_text)
system_pkgs = extract_packages(system_text)
third_pkgs = extract_packages(third_text)
disabled_pkgs = extract_packages(disabled_text)
enabled_pkgs = extract_packages(enabled_text)

vendor_prefixes = (
    "com.miui",
    "com.xiaomi",
    "com.mi.",
    "com.mipay",
    "com.duokan",
    "com.game.",
)

google_core = [
    "com.android.vending",
    "com.google.android.gms",
    "com.google.android.gsf",
    "com.google.android.apps.restore",
    "com.google.android.partnersetup",
    "com.google.android.webview",
    "com.android.chrome",
]

preserve_by_default_prefixes = (
    "android",
    "com.android",
    "com.google.android.gms",
    "com.google.android.gsf",
    "com.android.vending",
    "com.mediatek",
    "com.qualcomm",
)

xiaomi_candidates = sorted(pkg for pkg in all_pkgs if pkg.startswith(vendor_prefixes))
possible_cleanup_candidates = sorted(
    pkg for pkg in xiaomi_candidates
    if not pkg.startswith(preserve_by_default_prefixes)
)

summary = []
summary.append("# Clean Stock Feasibility Summary")
summary.append("")
summary.append("## Package counts")
summary.append("")
summary.append(f"- total packages: {len(all_pkgs)}")
summary.append(f"- system packages: {len(system_pkgs)}")
summary.append(f"- third-party packages: {len(third_pkgs)}")
summary.append(f"- enabled packages: {len(enabled_pkgs)}")
summary.append(f"- disabled packages: {len(disabled_pkgs)}")
summary.append(f"- Xiaomi or MIUI prefix packages: {len(xiaomi_candidates)}")
summary.append("")
summary.append("## Parser validation")
summary.append("")
summary.append(f"- all package parser source lines: {sum(1 for line in all_text.splitlines() if line.strip().startswith('package:'))}")
summary.append(f"- all package extracted count: {len(all_pkgs)}")
summary.append("")
summary.append("## Google core package presence")
summary.append("")
for pkg in google_core:
    summary.append(f"- {pkg}: {'present' if pkg in all_pkgs else 'missing'}")
summary.append("")
summary.append("## Xiaomi or MIUI package candidates")
summary.append("")
for pkg in xiaomi_candidates:
    summary.append(f"- {pkg}")
summary.append("")
summary.append("## Possible cleanup candidates")
summary.append("")
summary.append("These are candidates for future review only. This is not an uninstall list.")
summary.append("")
for pkg in possible_cleanup_candidates:
    summary.append(f"- {pkg}")
summary.append("")
summary.append("## Safety interpretation")
summary.append("")
summary.append("- This is inventory only.")
summary.append("- No package was uninstalled.")
summary.append("- No package was disabled.")
summary.append("- Google core packages should be treated as preserve-by-default.")
summary.append("- Android framework, MediaTek, modem, IMS, camera, sensor, WebView, Play Store, Play Services, and Google Services Framework packages should be treated as preserve-by-default.")
summary.append("- Candidate cleanup must be reviewed package by package before any ADB uninstall or disable command is generated.")
summary.append("")
summary.append("## Current conclusion")
summary.append("")
summary.append("Clean-stock feasibility is not decided yet. The next step is to classify Xiaomi or MIUI packages into preserve, optional remove, and unknown.")

(summary_dir / "shareable-summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")

(private_dir / "packages-all-extracted.txt").write_text("\n".join(all_pkgs) + "\n", encoding="utf-8")
(private_dir / "packages-system-extracted.txt").write_text("\n".join(system_pkgs) + "\n", encoding="utf-8")
(private_dir / "packages-third-party-extracted.txt").write_text("\n".join(third_pkgs) + "\n", encoding="utf-8")
(private_dir / "packages-enabled-extracted.txt").write_text("\n".join(enabled_pkgs) + "\n", encoding="utf-8")
(private_dir / "packages-disabled-extracted.txt").write_text("\n".join(disabled_pkgs) + "\n", encoding="utf-8")
(summary_dir / "xiaomi-miui-package-candidates.txt").write_text("\n".join(xiaomi_candidates) + "\n", encoding="utf-8")
(summary_dir / "possible-cleanup-candidates.txt").write_text("\n".join(possible_cleanup_candidates) + "\n", encoding="utf-8")
PY

cat > "${OUT_DIR}/03-shareable-summary/README.txt" <<EOF2
This folder is intended to be shareable.

It excludes the full third-party package list and preserves only:
- package counts
- Google core package presence
- Xiaomi or MIUI package candidates
- possible cleanup candidates
- safety interpretation

The full package inventory remains in:
${OUT_DIR}/02-packages-private
EOF2

cd "${PRIVATE_ROOT}" || exit 1
tar -czf "${RUN_ID}-shareable-summary.tar.gz" \
  "${RUN_ID}/00-context/run-context.txt" \
  "${RUN_ID}/00-context/host-baseline.txt" \
  "${RUN_ID}/01-adb/adb-devices.txt" \
  "${RUN_ID}/01-adb/device-state.txt" \
  "${RUN_ID}/03-shareable-summary"

echo
echo "summary created:"
echo "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
echo
sha256sum "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
ls -lh "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
echo
echo "preview:"
sed -n '1,260p' "${OUT_DIR}/03-shareable-summary/shareable-summary.txt"
