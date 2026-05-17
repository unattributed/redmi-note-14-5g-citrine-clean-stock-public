#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-alphadroid-release-integrity-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
LOG_FILE="${OUT_DIR}/run.log"

BASE_URL="https://sourceforge.net/projects/alphadroid-project/files/beryl"
PROJECT_URL="https://sourceforge.net/projects/alphadroid-project"
RSS_URL="https://sourceforge.net/projects/alphadroid-project/rss?path=/beryl"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-sourceforge" \
         "${OUT_DIR}/02-artifact-head" \
         "${OUT_DIR}/03-integrity-candidates" \
         "${OUT_DIR}/04-analysis" \
         "${OUT_DIR}/05-summary"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

safe_partial_get() {
  local name="$1"
  local url="$2"
  local body="${OUT_DIR}/01-sourceforge/${name}.partial"
  local headers="${OUT_DIR}/01-sourceforge/${name}.headers.txt"
  local curl_log="${OUT_DIR}/01-sourceforge/${name}.curl.txt"

  {
    echo "url: ${url}"
    echo "timestamp: $(date -Is)"
    echo "mode: capped partial GET"
    echo
    curl -L --connect-timeout 20 --max-time 90 \
      --max-filesize 2097152 \
      --range 0-1048576 \
      -D "${headers}" \
      -o "${body}" \
      "${url}"
    rc=$?
    echo
    echo "curl_exit=${rc}"
    echo "body=${body}"
    echo "headers=${headers}"
    [ -f "${body}" ] && wc -c "${body}"
  } > "${curl_log}" 2>&1

  return 0
}

head_only() {
  local out_dir="$1"
  local name="$2"
  local url="$3"
  local out="${out_dir}/${name}.head.txt"

  {
    echo "url: ${url}"
    echo "timestamp: $(date -Is)"
    echo "mode: HEAD only, no body download"
    echo
    curl -IL --connect-timeout 20 --max-time 90 "${url}"
    rc=$?
    echo
    echo "curl_exit=${rc}"
  } > "${out}" 2>&1

  return 0
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
alphadroid release integrity read-only collector
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
evidence_root: ${EVIDENCE_ROOT}
out_dir: ${OUT_DIR}
base_url: ${BASE_URL}
project_url: ${PROJECT_URL}
rss_url: ${RSS_URL}

safety:
- no phone modification
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no Google application sideloading
- no ROM download
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
  for tool in curl python3 tar sha256sum grep sed awk; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  curl --version 2>&1 | head -n 5 || true
  python3 --version 2>&1 || true
} > "${OUT_DIR}/00-context/host-baseline.txt" 2>&1

log "alphadroid release integrity read-only collector"
log "timestamp: $(date -Is)"
log "out_dir: ${OUT_DIR}"
log ""
log "safety: public metadata only, no phone modification, no ROM download"

safe_partial_get "sourceforge-beryl-folder" "${BASE_URL}/"
safe_partial_get "sourceforge-project-files" "${PROJECT_URL}/files/"
safe_partial_get "sourceforge-beryl-rss" "${RSS_URL}"

ARTIFACTS=(
  "AlphaDroid-16-20260423-gapps-beryl-v4.4.zip"
  "AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip"
  "vendor_boot.img"
)

for artifact in "${ARTIFACTS[@]}"; do
  safe_name="$(printf '%s' "${artifact}" | sed 's/[^A-Za-z0-9._-]/_/g')"
  head_only "${OUT_DIR}/02-artifact-head" "${safe_name}.download" "${BASE_URL}/${artifact}/download"
done

COMMON_INTEGRITY_NAMES=(
  "SHA256SUMS"
  "SHA256SUMS.txt"
  "sha256sums.txt"
  "sha256sum.txt"
  "checksums.txt"
  "checksum.txt"
  "MD5SUMS"
  "MD5SUMS.txt"
  "README"
  "README.txt"
  "README.md"
)

for name in "${COMMON_INTEGRITY_NAMES[@]}"; do
  safe_name="$(printf '%s' "${name}" | sed 's/[^A-Za-z0-9._-]/_/g')"
  head_only "${OUT_DIR}/03-integrity-candidates" "common-${safe_name}" "${BASE_URL}/${name}/download"
done

for artifact in "${ARTIFACTS[@]}"; do
  for suffix in ".sha256" ".sha256sum" ".sha256.txt" ".sha256sum.txt" ".md5" ".md5.txt" ".sig" ".asc" ".minisig"; do
    candidate="${artifact}${suffix}"
    safe_name="$(printf '%s' "${candidate}" | sed 's/[^A-Za-z0-9._-]/_/g')"
    head_only "${OUT_DIR}/03-integrity-candidates" "artifact-${safe_name}" "${BASE_URL}/${candidate}/download"
  done
done

OUT_DIR="${OUT_DIR}" python3 - <<'PY'
from pathlib import Path
import os
import re

root = Path(os.environ["OUT_DIR"])
analysis_dir = root / "04-analysis"
summary_dir = root / "05-summary"
analysis_dir.mkdir(parents=True, exist_ok=True)
summary_dir.mkdir(parents=True, exist_ok=True)

partial_text = ""
for path in sorted((root / "01-sourceforge").glob("*.partial")):
    partial_text += f"\n\n===== {path.name} =====\n"
    partial_text += path.read_text(encoding="utf-8", errors="replace")

artifacts = [
    "AlphaDroid-16-20260423-gapps-beryl-v4.4.zip",
    "AlphaDroid-16-20260423-vanilla-beryl-v4.4.zip",
    "vendor_boot.img",
]

terms = [
    "sha256", "sha-256", "checksum", "checksums", "signature", ".sig", ".asc",
    "md5", "source changelog", "device changelog", "flashing", "hyperos", "hos3",
    "vulkan", "gapps", "vanilla", "vendor_boot", "beryl", "citrine",
]

lines = []
lines.append("# AlphaDroid release integrity evidence summary")
lines.append("")
lines.append("## Public source keyword counts")
for term in terms:
    lines.append(f"- {term}: {partial_text.lower().count(term.lower())}")
lines.append("")

lines.append("## Artifact filename presence")
for artifact in artifacts:
    lines.append(f"- {artifact}: {'present' if artifact in partial_text else 'not found'}")
lines.append("")

header_files = sorted((root / "02-artifact-head").glob("*.head.txt"))
lines.append("## Artifact HEAD metadata")
for path in header_files:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines.append("")
    lines.append(f"### {path.name}")
    for raw in text.splitlines():
        line = raw.strip()
        low = line.lower()
        if line.startswith("HTTP/") or low.startswith("location:") or low.startswith("content-length:") or low.startswith("content-type:") or low.startswith("last-modified:") or low.startswith("etag:"):
            lines.append(f"- {line}")

lines.append("")
lines.append("## Integrity candidate HEAD results")
lines.append("")
lines.append("Interpretation rule: a candidate checksum or signature file is only useful if the HEAD trace clearly resolves to a plausible file, not merely a generic SourceForge redirect or HTML response.")
for path in sorted((root / "03-integrity-candidates").glob("*.head.txt")):
    text = path.read_text(encoding="utf-8", errors="replace")
    status_lines = [line.strip() for line in text.splitlines() if line.startswith("HTTP/")]
    content_types = [line.strip() for line in text.splitlines() if line.lower().startswith("content-type:")]
    content_lengths = [line.strip() for line in text.splitlines() if line.lower().startswith("content-length:")]
    locations = [line.strip() for line in text.splitlines() if line.lower().startswith("location:")]
    final_status = status_lines[-1] if status_lines else "no status"
    final_type = content_types[-1] if content_types else "no content-type"
    final_len = content_lengths[-1] if content_lengths else "no content-length"
    last_location = locations[-1] if locations else "no location"
    likely_plain = any(token in final_type.lower() for token in ["text/plain", "application/octet-stream", "binary/octet-stream"])
    likely_html = "text/html" in final_type.lower()
    label = "possible useful candidate" if ("200" in final_status and likely_plain and not likely_html) else "not proven useful"
    lines.append(f"- {path.name}: {label}; {final_status}; {final_type}; {final_len}; {last_location}")

lines.append("")
lines.append("## Current interpretation")
lines.append("")
lines.append("- This evidence uses capped public page retrieval and HEAD-only artifact and integrity candidate checks.")
lines.append("- It does not download ROM ZIP contents or image bodies.")
lines.append("- Exact artifact HTTP metadata can be captured without flashing or modifying the phone.")
lines.append("- Release integrity is not proven unless a trustworthy checksum or signature source is identified.")
lines.append("- Functional phone behavior is not proven.")
lines.append("- Google Play, Play Protect, Play Integrity, and sensitive app behavior are not proven.")
lines.append("- HyperOS 3 downgrade risk remains unresolved.")
lines.append("- Bootloader unlock remains no-go.")

payload = "\n".join(lines) + "\n"
(analysis_dir / "release-integrity-summary.txt").write_text(payload, encoding="utf-8")
(summary_dir / "summary.txt").write_text(payload, encoding="utf-8")
PY

log ""
log "== generated summary =="
sed -n '1,260p' "${OUT_DIR}/05-summary/summary.txt" | tee -a "${LOG_FILE}"

# Size guard before packaging. This collector should never produce large files.
large_files="$(find "${OUT_DIR}" -type f -size +10M -print)"
if [ -n "${large_files}" ]; then
  log ""
  log "ERROR: refusing to package because unexpected files over 10 MiB exist:"
  printf '%s\n' "${large_files}" | tee -a "${LOG_FILE}"
  exit 2
fi

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
