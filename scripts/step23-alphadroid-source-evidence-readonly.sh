#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-alphadroid-source-evidence-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/run.log"

mkdir -p "${OUT_DIR}"/{00-context,01-source-pages,02-analysis,03-summary}

touch "${LOG_FILE}"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

run_logged() {
  log ""
  log "== $* =="
  "$@" 2>&1 | tee -a "${LOG_FILE}"
}

fetch_url() {
  local label="$1"
  local url="$2"
  local out_base="${OUT_DIR}/01-source-pages/${label}"

  log ""
  log "== fetch ${label} =="
  log "url: ${url}"

  {
    echo "url=${url}"
    echo "timestamp=$(date -Is)"
    echo
    curl -IvL --connect-timeout 20 --max-time 60 "${url}"
  } > "${out_base}.headers.txt" 2>&1 || true

  curl -L --connect-timeout 20 --max-time 90 \
    -A "android-rom-dev-source-evidence/1.0" \
    "${url}" \
    -o "${out_base}.html" \
    > "${out_base}.curl.txt" 2>&1 || true

  {
    echo "url=${url}"
    echo "html_file=${out_base}.html"
    echo "headers_file=${out_base}.headers.txt"
    echo "curl_log=${out_base}.curl.txt"
    echo
    if [ -s "${out_base}.html" ]; then
      file "${out_base}.html" 2>&1 || true
      wc -c "${out_base}.html" 2>&1 || true
      sha256sum "${out_base}.html" 2>&1 || true
    else
      echo "html_fetch_result=missing_or_empty"
    fi
  } > "${out_base}.metadata.txt" 2>&1
}

{
  echo "alphadroid public source evidence collector"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "project_dir: ${PROJECT_DIR}"
  echo "out_dir: ${OUT_DIR}"
  echo
  echo "safety:"
  echo "- no phone modification"
  echo "- no bootloader unlock"
  echo "- no flashing"
  echo "- no userdata erase"
  echo "- no DSU install"
  echo "- no Google app sideload"
  echo "- public source page retrieval only"
} | tee "${OUT_DIR}/00-context/run-context.txt" | tee -a "${LOG_FILE}"

{
  echo "== host baseline =="
  date -Is
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  for tool in curl grep sed awk sha256sum tar file python3; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  curl --version 2>&1 || true
} > "${OUT_DIR}/00-context/host-baseline.txt" 2>&1

fetch_url "telemetr-alphadroid-releases" "https://telemetr.io/en/channels/1867278326-alphadroid_releases"
fetch_url "telemetr-alphadroid-releases-posts" "https://telemetr.io/en/channels/1867278326-alphadroid_releases/posts"
fetch_url "sourceforge-alphadroid-project" "https://sourceforge.net/projects/alphadroid-project/"
fetch_url "sourceforge-alphadroid-files" "https://sourceforge.net/projects/alphadroid-project/files/"
fetch_url "google-play-protect-certification" "https://support.google.com/googleplay/answer/7165974?hl=en"
fetch_url "google-gms" "https://www.android.com/gms/"
fetch_url "google-play-integrity" "https://developer.android.com/google/play/integrity/overview"

{
  echo "alphadroid beryl/citrine source extraction"
  echo "timestamp: $(date -Is)"
  echo

  for f in "${OUT_DIR}"/01-source-pages/*.html; do
    [ -f "$f" ] || continue
    echo "============================================================"
    echo "file: $f"
    echo "============================================================"
    grep -Ein \
      'AlphaDroid|Alphadroid|beryl|citrine|Redmi Note 14|POCO M7 Pro|GApps|Vanilla|Vendor Boot|Flash|HyperOS 3|downgrade|Vulkan|Naoko|checksum|sha256|signature|known bug|bug|Play Protect|Play Integrity|Google Play|GMS|certified' \
      "$f" \
      | sed -E 's/<[^>]+>/ /g; s/&nbsp;/ /g; s/&amp;/\&/g; s/[[:space:]]+/ /g' \
      | head -n 240 || true
    echo
  done
} > "${OUT_DIR}/02-analysis/keyword-extract.txt" 2>&1

python3 - <<PY > "${OUT_DIR}/02-analysis/alphadroid-source-evidence-summary.txt" 2>&1
from pathlib import Path
import re

out = Path("${OUT_DIR}")
text = "\n".join(p.read_text(errors="ignore") for p in (out / "01-source-pages").glob("*.html"))
terms = [
    "AlphaDroid", "Alphadroid", "beryl", "citrine", "Redmi Note 14", "POCO M7 Pro",
    "GApps", "Vanilla", "Vendor Boot", "HyperOS 3", "downgrade", "Vulkan",
    "Naoko", "Play Protect", "Play Integrity", "Google Play", "GMS", "checksum", "sha256",
]
print("AlphaDroid source evidence summary")
print(f"timestamp: __TIMESTAMP__")
print()
for term in terms:
    count = len(re.findall(re.escape(term), text, flags=re.IGNORECASE))
    print(f"{term}: {count}")
print()
print("interpretation:")
print("- Counts are keyword presence indicators only.")
print("- They do not prove functional phone behavior or release integrity.")
print("- Review keyword-extract.txt and source pages before changing project status.")
PY
sed -i "s/__TIMESTAMP__/$(date -Is | sed 's/[&/]/\\&/g')/" "${OUT_DIR}/02-analysis/alphadroid-source-evidence-summary.txt" 2>/dev/null || true

{
  echo "step 23 alphadroid public source evidence summary"
  echo "timestamp: $(date -Is)"
  echo
  echo "source pages captured:"
  find "${OUT_DIR}/01-source-pages" -maxdepth 1 -type f -name '*.html' -printf '%f %s bytes\n' | sort
  echo
  echo "source page metadata:"
  find "${OUT_DIR}/01-source-pages" -maxdepth 1 -type f -name '*.metadata.txt' -print0 \
    | sort -z \
    | xargs -0 -r -n1 sh -c 'echo "---- $1"; cat "$1"; echo' sh
  echo
  echo "safety result:"
  echo "- no phone modification"
  echo "- no bootloader unlock"
  echo "- no flashing"
  echo "- no userdata erase"
  echo "- no DSU install"
  echo "- no Google app sideload"
  echo
  echo "status: public source capture complete if pages are non-empty; functional proof still requires manual review."
} > "${OUT_DIR}/03-summary/summary.txt" 2>&1

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

log ""
log "upload this file:"
log "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
exit 0
