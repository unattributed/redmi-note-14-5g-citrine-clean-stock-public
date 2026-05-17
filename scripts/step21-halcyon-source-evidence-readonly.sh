#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-halcyon-source-evidence-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/00-context/run-log.txt"

mkdir -p "${OUT_DIR}"/{00-context,01-source-pages,02-link-analysis,03-summary}

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

fetch_url() {
  local label="$1"
  local url="$2"
  local base="${OUT_DIR}/01-source-pages/${label}"

  log ""
  log "== fetch ${label} =="
  log "url: ${url}"

  {
    echo "url=${url}"
    echo "timestamp=$(date -Is)"
    echo
    curl -L --fail --show-error --silent --max-time 45 --dump-header "${base}.headers.txt" --output "${base}.html" "${url}"
    rc=$?
    echo "curl_exit=${rc}"
    if [ "${rc}" -eq 0 ]; then
      echo "html_sha256=$(sha256sum "${base}.html" | awk '{print $1}')"
      echo "html_size_bytes=$(stat -c '%s' "${base}.html")"
      file "${base}.html" || true
    fi
  } 2>&1 | tee "${base}.fetch-log.txt" | tee -a "${LOG_FILE}"
}

cat > "${OUT_DIR}/00-context/safety.txt" <<'EOFSAFETY'
step 21 halcyon public source evidence

Safety boundary:
- no bootloader unlock
- no flashing
- no userdata erase
- no DSU install
- no Google application sideloading
- no Xiaomi account binding
- no phone modification
- public web source capture only
EOFSAFETY

{
  echo "step 21 halcyon public source evidence"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "project_dir: ${PROJECT_DIR}"
  echo "out_dir: ${OUT_DIR}"
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  for tool in curl python3 sha256sum tar grep sed awk; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
} 2>&1 | tee "${OUT_DIR}/00-context/context.txt" | tee -a "${LOG_FILE}"

fetch_url "halcyon-beryl-device" "https://wiki.hlcyn.co/devices/beryl/"
fetch_url "halcyon-supported-devices" "https://wiki.hlcyn.co/devices"
fetch_url "google-play-protect-certification" "https://support.google.com/android/answer/7165974?hl=en"
fetch_url "google-gms" "https://www.android.com/gms/"
fetch_url "google-gsi" "https://source.android.com/docs/core/tests/vts/gsi"
fetch_url "google-play-integrity" "https://developer.android.com/google/play/integrity/overview"

python3 - <<'PY' "${OUT_DIR}"
from html.parser import HTMLParser
from pathlib import Path
import re
import sys

out = Path(sys.argv[1])
source = out / "01-source-pages" / "halcyon-beryl-device.html"
links_out = out / "02-link-analysis" / "halcyon-beryl-links.txt"
summary_out = out / "03-summary" / "source-summary.txt"

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
    def handle_starttag(self, tag, attrs):
        if tag.lower() != "a":
            return
        data = dict(attrs)
        href = data.get("href")
        text = data.get("title", "")
        if href:
            self.links.append((href, text))

html = source.read_text(errors="replace") if source.exists() else ""
parser = LinkParser()
parser.feed(html)

links_out.write_text("\n".join(f"{href}\t{text}" for href, text in parser.links) + "\n", encoding="utf-8")

needles = {
    "mentions_redmi_note_14_5g": "Redmi Note 14 5G" in html,
    "mentions_poco_m7_pro_5g": "POCO M7 Pro 5G" in html,
    "mentions_beryl": "beryl" in html.lower(),
    "mentions_citrine": "citrine" in html.lower(),
    "mentions_vendor_boot": "vendor_boot" in html,
    "mentions_format_data": "Format data" in html or "format data" in html.lower(),
    "mentions_adb_sideload": "adb sideload" in html.lower(),
    "mentions_maintainer": "Maintainer" in html,
}

candidate_links = []
for href, text in parser.links:
    low = href.lower()
    if any(token in low for token in ["download", "build", "sourceforge", "github", "androidfilehost", "telegram", "ota", "beryl"]):
        candidate_links.append(href)

summary = []
summary.append("Halcyon public source evidence summary")
summary.append("")
for key, value in needles.items():
    summary.append(f"{key}: {str(value).lower()}")
summary.append("")
summary.append(f"total_links_found: {len(parser.links)}")
summary.append(f"candidate_links_found: {len(candidate_links)}")
summary.append("")
summary.append("candidate_links:")
for link in candidate_links:
    summary.append(f"- {link}")
summary.append("")
summary.append("interpretation:")
summary.append("- this evidence can support source review only")
summary.append("- it does not prove full phone functionality")
summary.append("- it does not approve unlock, flashing, data wipe, sideload, or relock")
summary_out.write_text("\n".join(summary) + "\n", encoding="utf-8")
PY

{
  echo "step 21 summary"
  echo "timestamp: $(date -Is)"
  echo
  cat "${OUT_DIR}/03-summary/source-summary.txt" 2>/dev/null || true
  echo
  echo "safety: public source capture only"
} 2>&1 | tee -a "${LOG_FILE}" | tee "${OUT_DIR}/03-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

log ""
log "upload this file:"
log "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"

exit 0
