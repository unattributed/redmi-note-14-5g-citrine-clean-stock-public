#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-alphadroid-functional-public-evidence-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/run.log"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-sources" \
         "${OUT_DIR}/02-analysis" \
         "${OUT_DIR}/03-summary"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

safe_name() {
  printf '%s' "$1" | sed 's#[^A-Za-z0-9._-]#_#g'
}

fetch_public_page() {
  local label="$1"
  local url="$2"
  local name
  name="$(safe_name "${label}")"
  local body="${OUT_DIR}/01-sources/${name}.partial.html"
  local headers="${OUT_DIR}/01-sources/${name}.headers.txt"
  local curl_log="${OUT_DIR}/01-sources/${name}.curl.txt"

  {
    echo "label: ${label}"
    echo "url: ${url}"
    echo "timestamp: $(date -Is)"
    echo
    echo "IMPORTANT: capped public page fetch. No ROM, image, or phone content is downloaded."
    echo
    curl -L --connect-timeout 20 --max-time 90 \
      --range 0-1048576 \
      -D "${headers}" \
      -o "${body}" \
      "${url}"
    rc=$?
    echo
    echo "curl_exit=${rc}"
    echo "body=${body}"
    echo "headers=${headers}"
    if [ -f "${body}" ]; then
      wc -c "${body}"
    fi
  } > "${curl_log}" 2>&1

  return 0
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
alphadroid functional public evidence read-only collector
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
evidence_root: ${EVIDENCE_ROOT}
out_dir: ${OUT_DIR}

safety:
- no phone modification
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no Google application sideloading
- no ROM download
- no image download
- public source evidence only
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

log "alphadroid functional public evidence read-only collector"
log "timestamp: $(date -Is)"
log "out_dir: ${OUT_DIR}"
log ""
log "safety: public pages only, no phone modification, no ROM download"

# Candidate and release sources already identified by the project.
fetch_public_page "sourceforge-alphadroid-beryl-folder" "https://sourceforge.net/projects/alphadroid-project/files/beryl/"
fetch_public_page "sourceforge-alphadroid-project" "https://sourceforge.net/projects/alphadroid-project/"
fetch_public_page "telemetr-alphadroid-releases" "https://telemetr.io/en/channels/1867278326-alphadroid_releases"

# Google trust constraints, official sources.
fetch_public_page "google-play-protect-certification" "https://support.google.com/googleplay/answer/7165974?hl=en"
fetch_public_page "google-play-integrity-overview" "https://developer.android.com/google/play/integrity/overview"
fetch_public_page "google-gms" "https://www.android.com/gms/"
fetch_public_page "android-gsi-docs" "https://source.android.com/docs/core/tests/vts/gsi"

# Guard against accidental large downloads before packaging.
{
  echo "== size guard before analysis =="
  date -Is
  echo
  find "${OUT_DIR}" -type f -printf '%s %p\n' | sort -n
  echo
  echo "== files larger than 10 MiB =="
  find "${OUT_DIR}" -type f -size +10M -printf '%s %p\n' | sort -n || true
} > "${OUT_DIR}/02-analysis/size-guard.txt" 2>&1

if find "${OUT_DIR}" -type f -size +10M | grep -q .; then
  log "ERROR: refusing to package evidence because a file larger than 10 MiB was captured."
  log "See: ${OUT_DIR}/02-analysis/size-guard.txt"
  exit 2
fi

OUT_DIR="${OUT_DIR}" python3 - <<'PY'
from pathlib import Path
import os
import re
from html import unescape

root = Path(os.environ["OUT_DIR"])
sources = root / "01-sources"
analysis = root / "02-analysis"
summary_dir = root / "03-summary"
analysis.mkdir(parents=True, exist_ok=True)
summary_dir.mkdir(parents=True, exist_ok=True)

functional_terms = [
    "modem", "cellular", "mobile data", "ims", "volte", "vowifi", "emergency",
    "wifi", "wi-fi", "bluetooth", "gnss", "gps", "location", "camera", "audio",
    "microphone", "mic", "sensor", "sensors", "usb", "charging", "battery", "suspend",
    "thermal", "vulkan", "gpu", "fingerprint", "nfc"
]
trust_terms = [
    "gapps", "google play", "play store", "play protect", "play integrity",
    "certified", "uncertified", "gms", "safetynet", "banking", "sensitive"
]
risk_terms = [
    "hyperos 3", "hos3", "downgrade", "do not install", "format data", "vendor_boot",
    "known bugs", "bugs", "changelog", "release notes", "checksum", "sha256", "signature",
    ".sig", ".asc"
]
all_terms = functional_terms + trust_terms + risk_terms

def clean_text(text: str) -> str:
    text = unescape(text)
    text = re.sub(r"<script.*?</script>", " ", text, flags=re.I | re.S)
    text = re.sub(r"<style.*?</style>", " ", text, flags=re.I | re.S)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def count_terms(text: str, terms: list[str]) -> dict[str, int]:
    lower = text.lower()
    return {term: lower.count(term.lower()) for term in terms}

def windows(text: str, terms: list[str], span: int = 280) -> list[str]:
    lower = text.lower()
    results = []
    for term in terms:
        needle = term.lower()
        start = 0
        hits = 0
        while True:
            idx = lower.find(needle, start)
            if idx < 0:
                break
            left = max(0, idx - span)
            right = min(len(text), idx + len(term) + span)
            snippet = text[left:right]
            snippet = re.sub(r"\s+", " ", snippet).strip()
            results.append(f"TERM={term}\n{snippet}\n")
            hits += 1
            if hits >= 4:
                break
            start = idx + len(term)
    return results

combined = ""
per_source_lines = []
for html in sorted(sources.glob("*.partial.html")):
    raw = html.read_text(encoding="utf-8", errors="replace")
    text = clean_text(raw)
    combined += "\n\nSOURCE: " + html.name + "\n" + text
    counts = count_terms(text, all_terms)
    source_report = []
    source_report.append(f"# Source analysis, {html.name}")
    source_report.append("")
    source_report.append(f"source_size_bytes: {html.stat().st_size}")
    source_report.append("")
    source_report.append("## Keyword counts")
    for term in all_terms:
        c = counts.get(term, 0)
        if c:
            source_report.append(f"- {term}: {c}")
    source_report.append("")
    source_report.append("## Context windows")
    context_terms = [t for t in all_terms if counts.get(t, 0)]
    source_report.extend(windows(text, context_terms))
    (analysis / f"{html.stem}.analysis.txt").write_text("\n".join(source_report) + "\n", encoding="utf-8")
    per_source_lines.append(f"- {html.name}: " + ", ".join(f"{k}={v}" for k, v in counts.items() if v))

combined_counts = count_terms(combined, all_terms)

lines = []
lines.append("# AlphaDroid functional public evidence summary")
lines.append("")
lines.append("## Scope")
lines.append("")
lines.append("This evidence is public source review only. It does not modify the phone, unlock the bootloader, download ROM artifacts, flash images, downgrade firmware, install DSU, or sideload Google applications.")
lines.append("")
lines.append("## Sources captured")
for f in sorted(sources.glob("*.partial.html")):
    lines.append(f"- {f.name}: {f.stat().st_size} bytes")
lines.append("")
lines.append("## Combined keyword counts")
for term in all_terms:
    lines.append(f"- {term}: {combined_counts.get(term, 0)}")
lines.append("")
lines.append("## Per-source nonzero keyword counts")
if per_source_lines:
    lines.extend(per_source_lines)
else:
    lines.append("- none")
lines.append("")
lines.append("## Functional phone proof status")
lines.append("")
required_functional = ["modem", "cellular", "ims", "volte", "camera", "battery", "thermal", "vulkan", "gpu"]
missing_or_unproven = [t for t in required_functional if combined_counts.get(t, 0) == 0]
lines.append("Functional phone behavior is not proven by this capture.")
if missing_or_unproven:
    lines.append("Missing or not meaningfully proven terms include: " + ", ".join(missing_or_unproven) + ".")
lines.append("")
lines.append("## Google trust proof status")
lines.append("")
lines.append("Google trust behavior is not proven by this capture. Public Google documentation confirms that GMS and Play Protect certification are separate constraints, but candidate-specific Play Protect, Play Integrity, and sensitive application behavior remain unproven.")
lines.append("")
lines.append("## Downgrade and install risk status")
lines.append("")
lines.append("The project still treats the HyperOS 3 downgrade warning, format-data workflow, vendor_boot dependency, and rollback feasibility as active blockers until candidate-specific evidence resolves them.")
lines.append("")
lines.append("## Track 2 conclusion")
lines.append("")
lines.append("Track 2 remains no-go. Continue source evidence collection only.")

payload = "\n".join(lines) + "\n"
(summary_dir / "summary.txt").write_text(payload, encoding="utf-8")
(analysis / "functional-public-evidence-summary.txt").write_text(payload, encoding="utf-8")
PY

log ""
log "== generated summary =="
sed -n '1,240p' "${OUT_DIR}/03-summary/summary.txt" | tee -a "${LOG_FILE}"

log ""
log "== final file sizes =="
find "${OUT_DIR}" -type f -printf '%s %p\n' | sort -n | tee -a "${LOG_FILE}"

if find "${OUT_DIR}" -type f -size +10M | grep -q .; then
  log "ERROR: refusing to package evidence because a file larger than 10 MiB was captured."
  exit 2
fi

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

{
  echo "functional public evidence collection complete"
  echo "timestamp: $(date -Is)"
  echo "evidence_dir: ${OUT_DIR}"
  echo "tarball: ${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
  echo
  sha256sum "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
  ls -lh "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
} | tee -a "${LOG_FILE}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
