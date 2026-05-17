#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-alphadroid-artifact-metadata-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/run.log"
BASE_URL="https://sourceforge.net/projects/alphadroid-project/files/beryl"
MAX_BODY_BYTES="2097152"
MAX_ALLOWED_FILE_BYTES="5242880"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-sourceforge" \
         "${OUT_DIR}/02-artifacts" \
         "${OUT_DIR}/03-analysis" \
         "${OUT_DIR}/04-summary"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

safe_head() {
  local label="$1"
  local url="$2"
  local out="${OUT_DIR}/02-artifacts/${label}.head.txt"

  {
    echo "label: ${label}"
    echo "url: ${url}"
    echo "timestamp: $(date -Is)"
    echo
    echo "method: HEAD only"
    echo "body_download: disabled"
    echo
    curl --head --location --connect-timeout 20 --max-time 90 --max-redirs 8 "${url}"
    echo
    echo "curl_exit=$?"
  } > "${out}" 2>&1
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
alphadroid artifact metadata strict no-body collector
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
evidence_root: ${EVIDENCE_ROOT}
out_dir: ${OUT_DIR}
base_url: ${BASE_URL}

safety:
- no phone modification
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no Google application sideloading
- no ROM ZIP download
- no artifact body download
- public source metadata only
CTX

{
  echo "== host baseline =="
  date -Is
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  for tool in curl python3 tar sha256sum grep sed awk find du; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  curl --version 2>&1 | head -n 5 || true
  python3 --version 2>&1 || true
} > "${OUT_DIR}/00-context/host-baseline.txt" 2>&1

log "alphadroid artifact metadata strict no-body collector"
log "timestamp: $(date -Is)"
log "out_dir: ${OUT_DIR}"
log ""
log "safety: public metadata only, no phone modification, no ROM download, HEAD-only for artifacts"

{
  echo "url: ${BASE_URL}/"
  echo "timestamp: $(date -Is)"
  echo "method: GET folder listing only"
  echo "max_body_bytes: ${MAX_BODY_BYTES}"
  echo
  curl --silent --show-error --location \
    --connect-timeout 20 \
    --max-time 60 \
    --max-filesize "${MAX_BODY_BYTES}" \
    --dump-header "${OUT_DIR}/01-sourceforge/sourceforge-beryl-folder.headers.txt" \
    --output "${OUT_DIR}/01-sourceforge/sourceforge-beryl-folder.partial.html" \
    "${BASE_URL}/"
  echo
  echo "curl_exit=$?"
  if [ -f "${OUT_DIR}/01-sourceforge/sourceforge-beryl-folder.partial.html" ]; then
    wc -c "${OUT_DIR}/01-sourceforge/sourceforge-beryl-folder.partial.html"
  fi
} > "${OUT_DIR}/01-sourceforge/sourceforge-beryl-folder.curl.txt" 2>&1 || true

cat > "${OUT_DIR}/02-artifacts/artifacts.txt" <<'ARTIFACTS'
AlphaDroid-16-20260423-gapps-beryl-v4.4.zip
AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip
vendor_boot.img
ARTIFACTS

while IFS= read -r artifact; do
  [ -n "${artifact}" ] || continue
  safe_name="$(printf '%s' "${artifact}" | sed 's/[^A-Za-z0-9._-]/_/g')"
  safe_head "${safe_name}" "${BASE_URL}/${artifact}/download"
done < "${OUT_DIR}/02-artifacts/artifacts.txt"

OUT_DIR="${OUT_DIR}" python3 - <<'PY'
from pathlib import Path
import os

root = Path(os.environ["OUT_DIR"])
folder = root / "01-sourceforge" / "sourceforge-beryl-folder.partial.html"
folder_text = folder.read_text(encoding="utf-8", errors="replace") if folder.exists() else ""
summary_path = root / "04-summary" / "summary.txt"
analysis_path = root / "03-analysis" / "artifact-metadata-summary.txt"

artifacts = [
    "AlphaDroid-16-20260423-gapps-beryl-v4.4.zip",
    "AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip",
    "vendor_boot.img",
]

lines = []
lines.append("# AlphaDroid artifact metadata, strict no-body capture")
lines.append("")
lines.append(f"folder_partial_present: {folder.exists()}")
lines.append(f"folder_partial_size_bytes: {folder.stat().st_size if folder.exists() else 0}")
lines.append("")
lines.append("## Artifact filename presence in folder listing")
for artifact in artifacts:
    lines.append(f"- {artifact}: {'present' if artifact in folder_text else 'not found'}")
lines.append("")
lines.append("## Folder keyword counts")
for term in ["AlphaDroid", "beryl", "citrine", "gapps", "vanilla", "vendor_boot", "sha256", "checksum", "signature", "HyperOS", "HOS3", "Vulkan"]:
    lines.append(f"- {term}: {folder_text.lower().count(term.lower())}")
lines.append("")
lines.append("## Artifact HEAD response highlights")
for head_file in sorted((root / "02-artifacts").glob("*.head.txt")):
    lines.append("")
    lines.append(f"### {head_file.name}")
    text = head_file.read_text(encoding="utf-8", errors="replace")
    seen = False
    for raw in text.splitlines():
        line = raw.strip()
        low = line.lower()
        if line.startswith("HTTP/") or low.startswith("location:") or low.startswith("content-length:") or low.startswith("content-type:") or low.startswith("last-modified:") or low.startswith("etag:"):
            lines.append(f"- {line}")
            seen = True
    if not seen:
        lines.append("- no highlighted headers captured")
lines.append("")
lines.append("## Interpretation")
lines.append("")
lines.append("- This evidence intentionally avoids downloading ROM ZIP or image bodies.")
lines.append("- Artifact URLs were queried with HEAD only.")
lines.append("- The SourceForge folder listing was capped by max-filesize.")
lines.append("- This does not prove release integrity unless checksums or signatures appear in public metadata.")
lines.append("- This does not prove functional phone behavior.")
lines.append("- This does not prove Google Play, Play Protect, Play Integrity, or sensitive app behavior.")
lines.append("- This does not approve bootloader unlock, downgrade, flashing, userdata erase, DSU installation, Google application sideloading, Xiaomi flash scripts, or relock.")
lines.append("")
lines.append("## Track 2 conclusion")
lines.append("")
lines.append("No-go for bootloader unlock. Continue source evidence collection only.")

payload = "\n".join(lines) + "\n"
summary_path.write_text(payload, encoding="utf-8")
analysis_path.write_text(payload, encoding="utf-8")
PY

{
  echo "== generated files =="
  find "${OUT_DIR}" -maxdepth 4 -type f | sort
  echo
  echo "== size guard =="
  find "${OUT_DIR}" -type f -size +"${MAX_ALLOWED_FILE_BYTES}"c -printf '%s %p\n' | sort -n || true
} > "${OUT_DIR}/04-summary/generated-files-and-size-guard.txt" 2>&1

large_count="$(find "${OUT_DIR}" -type f -size +"${MAX_ALLOWED_FILE_BYTES}"c | wc -l)"
if [ "${large_count}" -gt 0 ]; then
  log "ERROR: large files were captured unexpectedly. Refusing to package."
  log "See: ${OUT_DIR}/04-summary/generated-files-and-size-guard.txt"
  exit 1
fi

log ""
log "== generated summary =="
sed -n '1,220p' "${OUT_DIR}/04-summary/summary.txt" | tee -a "${LOG_FILE}"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

log ""
log "== completed =="
log "tarball: ${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
sha256sum "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz" | tee -a "${LOG_FILE}"
ls -lh "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz" | tee -a "${LOG_FILE}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
