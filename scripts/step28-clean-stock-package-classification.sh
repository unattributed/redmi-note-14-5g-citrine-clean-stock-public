#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
PRIVATE_ROOT="/home/foo/android-rom-dev-private-backups/clean-stock-feasibility"
RUN_ID="citrine-clean-stock-package-classification-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${PRIVATE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/run.log"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-input" \
         "${OUT_DIR}/02-classification-private" \
         "${OUT_DIR}/03-shareable-summary"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
clean stock package classification
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
out_dir: ${OUT_DIR}

purpose:
- classify Xiaomi or MIUI package candidates from Step 27 inventory
- identify preserve-by-default, review-only cleanup candidates, and unknown packages
- avoid uninstall, disable, flash, unlock, downgrade, or device modification

safety:
- no ADB package uninstall
- no ADB package disable
- no package modification
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- classification only
CTX

log "clean stock package classification"
log "timestamp: $(date -Is)"
log "out_dir: ${OUT_DIR}"
log ""
log "safety: classification only, no package changes"

LATEST_RUN_DIR="$(find "${PRIVATE_ROOT}" \
  -maxdepth 1 \
  -type d \
  -name 'citrine-clean-stock-feasibility-*' \
  -printf '%T@ %p\n' 2>/dev/null \
  | sort -n \
  | tail -n 1 \
  | cut -d' ' -f2- || true)"

if [ -z "${LATEST_RUN_DIR}" ] || [ ! -d "${LATEST_RUN_DIR}" ]; then
  log "No Step 27 clean-stock feasibility directory found."
  log "Run scripts/step27-clean-stock-feasibility-inventory.sh first."
  exit 1
fi

LATEST_SUMMARY="${LATEST_RUN_DIR}/03-shareable-summary/shareable-summary.txt"
LATEST_CANDIDATES="${LATEST_RUN_DIR}/03-shareable-summary/xiaomi-miui-package-candidates.txt"
LATEST_POSSIBLE="${LATEST_RUN_DIR}/03-shareable-summary/possible-cleanup-candidates.txt"

if [ -f "${LATEST_CANDIDATES}" ]; then
  cp -av "${LATEST_CANDIDATES}" "${OUT_DIR}/01-input/xiaomi-miui-package-candidates.txt" >/dev/null
elif [ -f "${LATEST_SUMMARY}" ]; then
  awk '
    /^## Xiaomi or MIUI package candidates/ {capture=1; next}
    /^## / && capture==1 {capture=0}
    capture==1 && /^- / {sub(/^- /, ""); print}
  ' "${LATEST_SUMMARY}" > "${OUT_DIR}/01-input/xiaomi-miui-package-candidates.txt"
else
  log "No Step 27 candidate file or shareable summary found in: ${LATEST_RUN_DIR}"
  exit 1
fi

if [ -f "${LATEST_SUMMARY}" ]; then
  cp -av "${LATEST_SUMMARY}" "${OUT_DIR}/01-input/step27-shareable-summary.txt" >/dev/null
fi

if [ -f "${LATEST_POSSIBLE}" ]; then
  cp -av "${LATEST_POSSIBLE}" "${OUT_DIR}/01-input/step27-possible-cleanup-candidates.txt" >/dev/null
fi

if [ ! -s "${OUT_DIR}/01-input/xiaomi-miui-package-candidates.txt" ]; then
  log "The Step 27 candidate list is empty. Refusing to produce misleading classification."
  exit 1
fi

OUT_DIR="${OUT_DIR}" python3 - <<'PY'
from pathlib import Path
import os

root = Path(os.environ["OUT_DIR"])
input_file = root / "01-input" / "xiaomi-miui-package-candidates.txt"
private_dir = root / "02-classification-private"
summary_dir = root / "03-shareable-summary"
private_dir.mkdir(parents=True, exist_ok=True)
summary_dir.mkdir(parents=True, exist_ok=True)

packages = []
for line in input_file.read_text(encoding="utf-8", errors="replace").splitlines():
    item = line.strip()
    if not item or item.startswith("#"):
        continue
    if item.startswith("-"):
        item = item[1:].strip()
    if item:
        packages.append(item)
packages = sorted(set(packages))

preserve_exact = {
    "com.miui.home",
    "com.miui.packageinstaller",
    "com.miui.powerkeeper",
    "com.miui.securitycenter",
    "com.xiaomi.account",
    "com.xiaomi.finddevice",
    "com.xiaomi.xmsf",
}

preserve_keywords = [
    "camera", "gallery", "media", "sound", "audio", "bluetooth", "wifi", "wlan",
    "telephony", "ims", "carrier", "mms", "sms", "contacts", "dialer", "incallui",
    "settings", "securitycenter", "securitycore", "permission", "packageinstaller",
    "updater", "ota", "backup", "restore", "cloudbackup", "cloudservice",
    "power", "battery", "thermal", "perf", "daemon", "service", "framework",
    "systemui", "home", "launcher", "pay", "wallet", "nfc", "auth", "account",
    "finddevice", "guardprovider", "trust", "webview", "keyboard", "input",
    "fileexplorer", "documentsui", "voip", "call", "calendar", "sync", "location",
]

review_cleanup_exact = {
    "com.miui.analytics",
    "com.xiaomi.discover",
    "com.xiaomi.mipicks",
}

review_cleanup_keywords = [
    "analytics", "msa", "mipicks", "discover", "gamecenter", "games", "recommend",
    "recommendation", "yellowpage", "browser", "globalbrowser", "video", "music",
    "weather", "wallpaper", "carousel", "personalassistant", "assistant", "quickapps",
    "hybrid", "advert", "ads", "bugreport", "feedback", "market", "appstore",
    "community", "remotecontroller", "miuiplayer", "newhome", "content", "plugin",
]

rows = []
for pkg in packages:
    lower = pkg.lower()
    if pkg in preserve_exact or any(key in lower for key in preserve_keywords):
        category = "preserve_by_default"
        reason = "may affect launcher, settings, security, updates, telephony, media, accounts, power, framework, location, or core device behavior"
    elif pkg in review_cleanup_exact or any(key in lower for key in review_cleanup_keywords):
        category = "review_cleanup_candidate"
        reason = "appears related to analytics, recommendations, app discovery, ads, games, content, optional media, or OEM promotional functions"
    else:
        category = "unknown_review_required"
        reason = "insufficient evidence for safe classification"
    rows.append((category, pkg, reason))

by_category = {
    "preserve_by_default": [],
    "review_cleanup_candidate": [],
    "unknown_review_required": [],
}
for category, pkg, reason in rows:
    by_category[category].append((pkg, reason))

(private_dir / "classification.tsv").write_text(
    "category\tpackage\treason\n" + "\n".join(f"{c}\t{p}\t{r}" for c, p, r in rows) + "\n",
    encoding="utf-8",
)

for category, items in by_category.items():
    (private_dir / f"{category}.txt").write_text(
        "\n".join(pkg for pkg, _ in items) + ("\n" if items else ""),
        encoding="utf-8",
    )

summary = []
summary.append("# Clean Stock Package Classification Summary")
summary.append("")
summary.append("## Current status")
summary.append("")
summary.append("Package classification completed from the latest Step 27 Xiaomi or MIUI candidate inventory.")
summary.append("")
summary.append("This is classification only. It is not an uninstall list and it does not approve disabling packages.")
summary.append("")
summary.append("## Counts")
summary.append("")
summary.append(f"- Xiaomi or MIUI packages reviewed: {len(packages)}")
summary.append(f"- preserve by default: {len(by_category['preserve_by_default'])}")
summary.append(f"- review-only cleanup candidates: {len(by_category['review_cleanup_candidate'])}")
summary.append(f"- unknown, review required: {len(by_category['unknown_review_required'])}")
summary.append("")
summary.append("## Review-only cleanup candidates")
summary.append("")
summary.append("These packages may be reasonable future cleanup candidates, but each must be reviewed before any command is generated.")
summary.append("")
for pkg, reason in by_category["review_cleanup_candidate"]:
    summary.append(f"- {pkg}")
summary.append("")
summary.append("## Unknown packages requiring review")
summary.append("")
for pkg, reason in by_category["unknown_review_required"]:
    summary.append(f"- {pkg}")
summary.append("")
summary.append("## Preserve-by-default packages")
summary.append("")
summary.append("These packages are treated as preserve-by-default because they may affect core device behavior, framework behavior, accounts, security, telephony, power, media, or user interface behavior.")
summary.append("")
for pkg, reason in by_category["preserve_by_default"]:
    summary.append(f"- {pkg}")
summary.append("")
summary.append("## Safety boundary")
summary.append("")
summary.append("- No package was uninstalled.")
summary.append("- No package was disabled.")
summary.append("- No ADB package change command was generated.")
summary.append("- Future cleanup must use a restore-first approach and should start with the smallest low-risk review-only candidate set.")
summary.append("")
summary.append("## Current conclusion")
summary.append("")
summary.append("Clean-stock feasibility remains promising, but not proven. The next step is manual review of review-only cleanup candidates and creation of a reversible test plan.")

(summary_dir / "classification-summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")

readme = []
readme.append("Step 28 shareable package classification summary")
readme.append("")
readme.append("This shareable output excludes full third-party package inventory.")
readme.append("It contains only classification of Xiaomi or MIUI candidate packages produced from Step 27.")
readme.append("")
readme.append("No phone modification occurred.")
(summary_dir / "README.txt").write_text("\n".join(readme) + "\n", encoding="utf-8")
PY

cd "${PRIVATE_ROOT}" || exit 1
tar -czf "${RUN_ID}-shareable-summary.tar.gz" \
  "${RUN_ID}/00-context" \
  "${RUN_ID}/01-input" \
  "${RUN_ID}/03-shareable-summary"

log ""
log "summary created:"
log "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
sha256sum "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz" | tee -a "${LOG_FILE}"
ls -lh "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz" | tee -a "${LOG_FILE}"
log ""
log "preview:"
sed -n '1,260p' "${OUT_DIR}/03-shareable-summary/classification-summary.txt" | tee -a "${LOG_FILE}"
