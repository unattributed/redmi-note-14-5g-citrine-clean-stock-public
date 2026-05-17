#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
PRIVATE_ROOT="/home/foo/android-rom-dev-private-backups/clean-stock-feasibility"
RUN_ID="citrine-clean-stock-command-plan-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${PRIVATE_ROOT}/${RUN_ID}"

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-input" \
         "${OUT_DIR}/02-command-plan" \
         "${OUT_DIR}/03-shareable-summary"

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
clean stock restore-first command plan generator
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
private_root: ${PRIVATE_ROOT}
out_dir: ${OUT_DIR}

purpose:
- generate restore-first package cleanup command plans
- produce reviewable commands only
- avoid executing any package removal or disablement

safety:
- no package uninstall is executed
- no package disable is executed
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no custom ROM install
- no root action
- no relock
CTX

{
  echo "== host baseline =="
  date -Is
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  for tool in python3 tar sha256sum find sort awk sed grep; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
} > "${OUT_DIR}/00-context/host-baseline.txt" 2>&1

LATEST_STEP28="$(find "${PRIVATE_ROOT}" -maxdepth 1 -type d -name 'citrine-clean-stock-package-classification-*' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"

if [ -z "${LATEST_STEP28}" ] || [ ! -d "${LATEST_STEP28}" ]; then
  echo "No Step 28 classification directory found under ${PRIVATE_ROOT}" >&2
  exit 1
fi

CLASSIFICATION_SUMMARY="${LATEST_STEP28}/03-shareable-summary/classification-summary.txt"
if [ ! -f "${CLASSIFICATION_SUMMARY}" ]; then
  echo "Step 28 classification summary not found: ${CLASSIFICATION_SUMMARY}" >&2
  exit 1
fi

printf '%s\n' "${LATEST_STEP28}" > "${OUT_DIR}/01-input/latest-step28-directory.txt"
cp -av "${CLASSIFICATION_SUMMARY}" "${OUT_DIR}/01-input/classification-summary.txt" >/dev/null

OUT_DIR="${OUT_DIR}" CLASSIFICATION_SUMMARY="${CLASSIFICATION_SUMMARY}" python3 - <<'PY'
from pathlib import Path
import os

out_dir = Path(os.environ["OUT_DIR"])
summary_path = Path(os.environ["CLASSIFICATION_SUMMARY"])
text = summary_path.read_text(encoding="utf-8", errors="replace")

sections = {}
current = None
for raw in text.splitlines():
    line = raw.rstrip()
    if line.startswith("## "):
        current = line[3:].strip()
        sections[current] = []
        continue
    if current:
        sections[current].append(line)

review_lines = sections.get("Review-only cleanup candidates", [])
review_candidates = []
for line in review_lines:
    line = line.strip()
    if line.startswith("- "):
        pkg = line[2:].strip()
        if pkg and not pkg.lower().startswith("these packages"):
            review_candidates.append(pkg)

preferred_first_batch = [
    "com.miui.analytics",
    "com.miui.msa.global",
    "com.miui.thirdappassistant",
]

first_batch = [pkg for pkg in preferred_first_batch if pkg in review_candidates]
if not first_batch:
    first_batch = review_candidates[:3]

plan_dir = out_dir / "02-command-plan"
summary_dir = out_dir / "03-shareable-summary"
plan_dir.mkdir(parents=True, exist_ok=True)
summary_dir.mkdir(parents=True, exist_ok=True)

(plan_dir / "all-review-only-cleanup-candidates.txt").write_text("\n".join(review_candidates) + ("\n" if review_candidates else ""), encoding="utf-8")
(plan_dir / "first-batch-candidates.txt").write_text("\n".join(first_batch) + ("\n" if first_batch else ""), encoding="utf-8")

restore_cmds = []
state_cmds = []
removal_cmds = []

for pkg in first_batch:
    restore_cmds.append(f"adb shell cmd package install-existing --user 0 {pkg}")
    state_cmds.append(f"adb shell pm path {pkg} || true")
    state_cmds.append(f"adb shell dumpsys package {pkg} 2>/dev/null | grep -E 'Package \\[|versionName=|enabled=|hidden=|installerPackageName=' | head -n 40 || true")
    removal_cmds.append(f"# NOT APPROVED: adb shell pm uninstall --user 0 {pkg}")

(plan_dir / "first-batch-restore-commands.txt").write_text("\n".join(restore_cmds) + ("\n" if restore_cmds else ""), encoding="utf-8")
(plan_dir / "first-batch-state-check-commands.txt").write_text("\n".join(state_cmds) + ("\n" if state_cmds else ""), encoding="utf-8")
(plan_dir / "first-batch-removal-commands-not-approved.txt").write_text("\n".join(removal_cmds) + ("\n" if removal_cmds else ""), encoding="utf-8")

review_script = [
    "#!/usr/bin/env bash",
    "set -euo pipefail",
    "echo 'review only, this script does not remove packages'",
    "echo 'first batch candidates:'",
]
for pkg in first_batch:
    review_script.append(f"echo '  - {pkg}'")
review_script.extend([
    "echo",
    "echo 'restore commands that must be available before any removal:'",
])
for cmd in restore_cmds:
    review_script.append(f"echo {cmd!r}")
review_script.extend([
    "echo",
    "echo 'removal commands, not approved for execution yet:'",
])
for cmd in removal_cmds:
    review_script.append(f"echo {cmd!r}")
review_script.extend([
    "echo",
    "echo 'This script intentionally exits before executing any adb package command.'",
    "exit 0",
])
(plan_dir / "review-only-command-plan.sh").write_text("\n".join(review_script) + "\n", encoding="utf-8")

readme = []
readme.append("# Clean Stock Restore-First Command Plan")
readme.append("")
readme.append("## Current status")
readme.append("")
readme.append("This is command planning only. No package removal or disablement is approved.")
readme.append("")
readme.append("## Source")
readme.append("")
readme.append(f"- Step 28 input directory: `{out_dir / '01-input'}`")
readme.append(f"- Review-only cleanup candidates found: `{len(review_candidates)}`")
readme.append(f"- First batch candidate count: `{len(first_batch)}`")
readme.append("")
readme.append("## First batch candidates")
readme.append("")
if first_batch:
    for pkg in first_batch:
        readme.append(f"- `{pkg}`")
else:
    readme.append("- none")
readme.append("")
readme.append("## Restore-first rule")
readme.append("")
readme.append("Every package in the first batch has a restore command generated before any removal command is considered.")
readme.append("")
readme.append("Restore pattern:")
readme.append("")
readme.append("```text")
readme.append("adb shell cmd package install-existing --user 0 PACKAGE_NAME")
readme.append("```")
readme.append("")
readme.append("Removal pattern, not approved yet:")
readme.append("")
readme.append("```text")
readme.append("adb shell pm uninstall --user 0 PACKAGE_NAME")
readme.append("```")
readme.append("")
readme.append("## Generated files")
readme.append("")
readme.append("- `02-command-plan/first-batch-restore-commands.txt`")
readme.append("- `02-command-plan/first-batch-removal-commands-not-approved.txt`")
readme.append("- `02-command-plan/first-batch-state-check-commands.txt`")
readme.append("- `02-command-plan/all-review-only-cleanup-candidates.txt`")
readme.append("- `02-command-plan/review-only-command-plan.sh`")
readme.append("")
readme.append("## Safety boundary")
readme.append("")
readme.append("The generated commands are not approved for execution. The next step is to review the plan, select one package, and create a baseline and restore test procedure before any package command is executed.")
readme.append("")
readme.append("## Current conclusion")
readme.append("")
if first_batch:
    readme.append("Clean-stock cleanup remains promising. The first batch command plan is ready for review, but no package change is approved yet.")
else:
    readme.append("Clean-stock cleanup remains promising, but no package change is approved yet.")

payload = "\n".join(readme) + "\n"
(plan_dir / "README.md").write_text(payload, encoding="utf-8")
(summary_dir / "shareable-summary.txt").write_text(payload, encoding="utf-8")
PY

chmod 0755 "${OUT_DIR}/02-command-plan/review-only-command-plan.sh"

cat > "${OUT_DIR}/03-shareable-summary/README.txt" <<EOF2
This folder is intended to be shareable.

It contains the Step 30 command-plan summary and excludes the full private package inventory.

The command plan is generated under:
${OUT_DIR}/02-command-plan

No package commands were executed.
EOF2

cd "${PRIVATE_ROOT}" || exit 1
tar -czf "${RUN_ID}-shareable-summary.tar.gz" \
  "${RUN_ID}/00-context" \
  "${RUN_ID}/01-input/latest-step28-directory.txt" \
  "${RUN_ID}/01-input/classification-summary.txt" \
  "${RUN_ID}/02-command-plan" \
  "${RUN_ID}/03-shareable-summary"

echo

echo "summary created:"
echo "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
echo
sha256sum "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
ls -lh "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz"
echo

echo "preview:"
sed -n '1,220p' "${OUT_DIR}/03-shareable-summary/shareable-summary.txt"
