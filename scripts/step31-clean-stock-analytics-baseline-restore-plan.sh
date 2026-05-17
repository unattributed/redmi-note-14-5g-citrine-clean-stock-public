#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
PRIVATE_ROOT="/home/foo/android-rom-dev-private-backups/clean-stock-feasibility"
TARGET_PACKAGE="com.miui.analytics"
RUN_ID="citrine-clean-stock-analytics-baseline-restore-plan-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${PRIVATE_ROOT}/${RUN_ID}"
STATUS_DOC="${PROJECT_DIR}/docs/13-clean-stock-feasibility/clean-stock-analytics-baseline-restore-plan-2026-05-17.md"
BUNDLE_MANIFEST="${PROJECT_DIR}/evidence/manifests/evidence-bundles.md"
CODE_FENCE='```'

mkdir -p "${OUT_DIR}/00-context" \
         "${OUT_DIR}/01-adb-baseline" \
         "${OUT_DIR}/02-package-baseline" \
         "${OUT_DIR}/03-restore-plan" \
         "${OUT_DIR}/04-human-checklist" \
         "${OUT_DIR}/05-shareable-summary" \
         "${PROJECT_DIR}/evidence/bundles" \
         "${PROJECT_DIR}/evidence/manifests"

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

run_adb_capture() {
  local out_file="$1"
  shift
  run_capture "${out_file}" adb "$@"
}

cat > "${OUT_DIR}/00-context/run-context.txt" <<CTX
clean stock analytics baseline and restore planning
step: 31
timestamp: $(date -Is)
hostname: $(hostname)
user: $(whoami)
project_dir: ${PROJECT_DIR}
private_root: ${PRIVATE_ROOT}
out_dir: ${OUT_DIR}
target_package: ${TARGET_PACKAGE}

purpose:
- collect a one-package baseline for ${TARGET_PACKAGE}
- verify that restore planning exists before any future package removal test
- keep this phase read-only against the phone

safety:
- no package uninstall is executed
- no package disable is executed
- no install-existing restore command is executed
- no bootloader unlock
- no flashing
- no userdata erase
- no downgrade
- no DSU install
- no custom ROM install
- no root action
- no relock
- no Xiaomi flash script execution
CTX

run_capture "${OUT_DIR}/00-context/host-baseline.txt" bash -c '
cat /etc/os-release 2>/dev/null || true
echo
uname -a
echo
for tool in adb git tar sha256sum find sort awk sed grep date; do
  printf "%-12s " "${tool}:"
  command -v "${tool}" || true
done
echo
adb version 2>&1 || true
echo
git -C /home/foo/Workspace/android-rom-dev status --short 2>&1 || true
echo
git -C /home/foo/Workspace/android-rom-dev log --oneline -5 2>&1 || true
'

log "step 31 clean stock analytics baseline and restore planning"
log "timestamp: $(date -Is)"
log "target_package: ${TARGET_PACKAGE}"
log "out_dir: ${OUT_DIR}"
log ""
log "waiting for adb device"

adb start-server >/dev/null 2>&1 || true

ADB_READY="no"
for attempt in $(seq 1 24); do
  if adb get-state >/dev/null 2>&1; then
    ADB_READY="yes"
    break
  fi
  log "adb not ready, attempt ${attempt}/24"
  sleep 2
done

if [ "${ADB_READY}" != "yes" ]; then
  log "adb device was not ready"
  run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-devices-l.txt" devices -l
  exit 1
fi

run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-devices-l.txt" devices -l
run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-shell-getprop-selected.txt" shell sh -c 'getprop ro.product.device; getprop ro.product.model; getprop ro.build.version.release; getprop ro.build.version.incremental; getprop ro.boot.verifiedbootstate; getprop ro.boot.flash.locked'
run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-shell-user-list.txt" shell pm list users
run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-shell-disabled-packages-user0.txt" shell pm list packages -d --user 0
run_adb_capture "${OUT_DIR}/01-adb-baseline/adb-shell-enabled-target-filter-user0.txt" shell pm list packages -e --user 0 "${TARGET_PACKAGE}"

run_adb_capture "${OUT_DIR}/02-package-baseline/pm-list-target-user0.txt" shell pm list packages --user 0 "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/pm-list-target-system.txt" shell pm list packages -s "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/pm-list-target-disabled-user0.txt" shell pm list packages -d --user 0 "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/pm-list-target-enabled-user0.txt" shell pm list packages -e --user 0 "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/pm-path-target.txt" shell pm path "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/dumpsys-package-target-full.txt" shell dumpsys package "${TARGET_PACKAGE}"
run_adb_capture "${OUT_DIR}/02-package-baseline/dumpsys-package-target-summary.txt" shell sh -c "dumpsys package ${TARGET_PACKAGE} 2>/dev/null | grep -E 'Package \\[|userId=|versionCode=|versionName=|enabled=|hidden=|installed=|stopped=|installerPackageName=|pkgFlags=|privateFlags=' | head -n 80"

PACKAGE_LISTING="$(adb shell pm list packages --user 0 "${TARGET_PACKAGE}" 2>/dev/null | tr -d '\r' || true)"
PACKAGE_PATH="$(adb shell pm path "${TARGET_PACKAGE}" 2>/dev/null | tr -d '\r' || true)"
DISABLED_LISTING="$(adb shell pm list packages -d --user 0 "${TARGET_PACKAGE}" 2>/dev/null | tr -d '\r' || true)"
ENABLED_LISTING="$(adb shell pm list packages -e --user 0 "${TARGET_PACKAGE}" 2>/dev/null | tr -d '\r' || true)"

PACKAGE_PRESENT="no"
PACKAGE_ENABLED="unknown"
PACKAGE_DISABLED="unknown"
PACKAGE_SYSTEM_PATH="unknown"

if printf '%s\n' "${PACKAGE_LISTING}" | grep -qx "package:${TARGET_PACKAGE}"; then
  PACKAGE_PRESENT="yes"
fi

if printf '%s\n' "${ENABLED_LISTING}" | grep -qx "package:${TARGET_PACKAGE}"; then
  PACKAGE_ENABLED="yes"
else
  PACKAGE_ENABLED="no"
fi

if printf '%s\n' "${DISABLED_LISTING}" | grep -qx "package:${TARGET_PACKAGE}"; then
  PACKAGE_DISABLED="yes"
else
  PACKAGE_DISABLED="no"
fi

if [ -n "${PACKAGE_PATH}" ]; then
  PACKAGE_SYSTEM_PATH="present"
fi

cat > "${OUT_DIR}/02-package-baseline/package-baseline-result.txt" <<RESULT
package: ${TARGET_PACKAGE}
package_present_for_user0: ${PACKAGE_PRESENT}
package_enabled_for_user0: ${PACKAGE_ENABLED}
package_disabled_for_user0: ${PACKAGE_DISABLED}
package_path_state: ${PACKAGE_SYSTEM_PATH}

interpretation:
- package_present_for_user0 should be yes before any future removal test.
- package_path_state should be present before relying on install-existing restore planning.
- this step does not prove future removal is safe.
RESULT

cat > "${OUT_DIR}/03-restore-plan/restore-command-planned-not-executed.txt" <<RESTORE
adb shell cmd package install-existing --user 0 ${TARGET_PACKAGE}
RESTORE

cat > "${OUT_DIR}/03-restore-plan/future-removal-command-not-approved.txt" <<REMOVE
# not approved for step 31
# adb shell pm uninstall --user 0 ${TARGET_PACKAGE}
REMOVE

cat > "${OUT_DIR}/03-restore-plan/restore-verification-plan.md" <<PLAN
# Restore Verification Plan for ${TARGET_PACKAGE}

## Scope

This file is planning only. Step 31 does not execute package removal, package disablement, or restore.

## Required baseline before any future removal

- Confirm the package exists for user 0.
- Confirm pm path ${TARGET_PACKAGE} returns a system package path.
- Confirm the package is not already disabled for user 0.
- Record full dumpsys package ${TARGET_PACKAGE} output.
- Record human phone baseline before any package change.

## Planned restore command, not executed in Step 31

${CODE_FENCE}text
adb shell cmd package install-existing --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

## Future removal command, not approved in Step 31

${CODE_FENCE}text
adb shell pm uninstall --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

## Future success criteria

A future package test may only be considered if the restore command is documented first, the phone remains usable after a single package change, and the restore command returns the package to user 0.
PLAN

cat > "${OUT_DIR}/04-human-checklist/pre-change-human-checklist.md" <<CHECKLIST
# Pre-Change Human Checklist for ${TARGET_PACKAGE}

Before any future package modification, manually confirm and record:

- boot completes normally
- lock screen unlocks normally
- touchscreen works
- launcher opens
- settings opens
- phone app opens
- SMS app opens
- Wi-Fi state is unchanged
- mobile data state is unchanged
- camera opens
- Play Store opens
- Chrome or WebView-backed browsing works
- notifications are not obviously broken
- no repeated crash dialogs are visible

Step 31 does not perform any package modification.
CHECKLIST

cat > "${OUT_DIR}/05-shareable-summary/shareable-summary.md" <<SUMMARY
# Step 31 Clean Stock Analytics Baseline and Restore Plan

## Current status

Step 31 collected a one-package baseline and restore plan for:

${CODE_FENCE}text
${TARGET_PACKAGE}
${CODE_FENCE}

## Safety boundary

No package uninstall, package disablement, package restore command, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was performed.

## Baseline result

${CODE_FENCE}text
package_present_for_user0: ${PACKAGE_PRESENT}
package_enabled_for_user0: ${PACKAGE_ENABLED}
package_disabled_for_user0: ${PACKAGE_DISABLED}
package_path_state: ${PACKAGE_SYSTEM_PATH}
${CODE_FENCE}

## Restore command planned, not executed

${CODE_FENCE}text
adb shell cmd package install-existing --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

## Future removal command, not approved

${CODE_FENCE}text
adb shell pm uninstall --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

## Current conclusion

The project remains in restore-first planning. The next step may only consider a single-package test after explicit approval.
SUMMARY

cat > "${OUT_DIR}/05-shareable-summary/README.txt" <<README
This folder is intended to be shareable.

It contains the Step 31 one-package baseline and restore plan summary for ${TARGET_PACKAGE}.

The full dumpsys package output remains in the private evidence directory.

No package commands were executed.
README

cd "${PRIVATE_ROOT}"
tar -czf "${RUN_ID}-shareable-summary.tar.gz" \
  "${RUN_ID}/00-context" \
  "${RUN_ID}/02-package-baseline/package-baseline-result.txt" \
  "${RUN_ID}/03-restore-plan" \
  "${RUN_ID}/04-human-checklist" \
  "${RUN_ID}/05-shareable-summary"

cp -av "${PRIVATE_ROOT}/${RUN_ID}-shareable-summary.tar.gz" "${PROJECT_DIR}/evidence/bundles/" >/dev/null

cat > "${STATUS_DOC}" <<DOC
# Clean Stock Analytics Baseline and Restore Plan, 2026-05-17

## Current status

Step 31 collected a one-package baseline and restore planning record for:

${CODE_FENCE}text
${TARGET_PACKAGE}
${CODE_FENCE}

This is still planning and evidence collection only.

No package removal, package disablement, restore command execution, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was approved or performed.

## Evidence bundle

${CODE_FENCE}text
${RUN_ID}-shareable-summary.tar.gz
${CODE_FENCE}

## Baseline result

${CODE_FENCE}text
package_present_for_user0: ${PACKAGE_PRESENT}
package_enabled_for_user0: ${PACKAGE_ENABLED}
package_disabled_for_user0: ${PACKAGE_DISABLED}
package_path_state: ${PACKAGE_SYSTEM_PATH}
${CODE_FENCE}

## Restore-first rule

The restore command exists before any future removal command is considered.

Restore command, planned only:

${CODE_FENCE}text
adb shell cmd package install-existing --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

Future removal command, not approved:

${CODE_FENCE}text
adb shell pm uninstall --user 0 ${TARGET_PACKAGE}
${CODE_FENCE}

## Required human baseline before any future package change

Before any future package modification, record that these still work:

- boot completes normally,
- lock screen unlocks normally,
- touchscreen works,
- launcher opens,
- settings opens,
- phone app opens,
- SMS app opens,
- Wi-Fi state is unchanged,
- mobile data state is unchanged,
- camera opens,
- Play Store opens,
- Chrome or WebView-backed browsing works,
- notifications are not obviously broken,
- no repeated crash dialogs are visible.

## Safety boundary

Step 31 does not approve execution of either the future removal command or the restore command.

## Current conclusion

Clean-stock cleanup remains promising, but the project is still in restore-first planning.

The next step may only consider a single-package test for ${TARGET_PACKAGE} if explicitly approved.
DOC

{
  echo "# Evidence Bundle Manifest"
  echo
  echo "Generated: $(date -Is)"
  echo
  echo "| SHA256 | Size bytes | Bundle |"
  echo "| --- | ---: | --- |"
  find "${PROJECT_DIR}/evidence/bundles" -maxdepth 1 -type f -name '*.tar.gz' -printf '%f\n' | sort | while read -r bundle; do
    sha="$(sha256sum "${PROJECT_DIR}/evidence/bundles/${bundle}" | awk '{print $1}')"
    size="$(stat -c '%s' "${PROJECT_DIR}/evidence/bundles/${bundle}")"
    printf '| `%s` | %s | `%s` |\n' "${sha}" "${size}" "${bundle}"
  done
} > "${BUNDLE_MANIFEST}"

log ""
log "step 31 complete"
log "private_output_dir: ${OUT_DIR}"
log "repo_bundle: ${PROJECT_DIR}/evidence/bundles/${RUN_ID}-shareable-summary.tar.gz"
log "status_doc: ${STATUS_DOC}"
log "manifest: ${BUNDLE_MANIFEST}"
log ""
log "repo status:"
git -C "${PROJECT_DIR}" status --short
