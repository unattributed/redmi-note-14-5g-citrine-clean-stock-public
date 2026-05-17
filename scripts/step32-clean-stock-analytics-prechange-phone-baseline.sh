#!/usr/bin/env bash
set -Eeuo pipefail

# Step 32, clean-stock analytics pre-change phone baseline.
# This script is read-only with respect to Android package state.
# It does not uninstall, disable, restore, flash, erase, downgrade, sideload, unlock, relock, or execute Xiaomi flash scripts.

PKG="com.miui.analytics"
REPO_ROOT="${REPO_ROOT:-/home/foo/Workspace/android-rom-dev}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
DOC_DATE="$(date +%Y-%m-%d)"
DOC_DATE_TITLE="$(date +%Y-%m-%d)"
PRIVATE_DIR="${REPO_ROOT}/evidence/private/citrine-clean-stock-analytics-prechange-phone-baseline-${RUN_ID}"
SHARE_DIR="${PRIVATE_DIR}/shareable-summary"
BUNDLE_NAME="citrine-clean-stock-analytics-prechange-phone-baseline-${RUN_ID}-shareable-summary.tar.gz"
BUNDLE_PATH="${REPO_ROOT}/evidence/bundles/${BUNDLE_NAME}"
DOC_PATH="${REPO_ROOT}/docs/13-clean-stock-feasibility/clean-stock-analytics-prechange-phone-baseline-${DOC_DATE}.md"
MANIFEST_PATH="${REPO_ROOT}/evidence/manifests/evidence-bundles.md"

mkdir -p \
  "${PRIVATE_DIR}" \
  "${SHARE_DIR}" \
  "${REPO_ROOT}/evidence/bundles" \
  "${REPO_ROOT}/evidence/manifests" \
  "${REPO_ROOT}/docs/13-clean-stock-feasibility"

log() {
  printf '[step32] %s\n' "$*"
}

fail() {
  printf '[step32][error] %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

adb_capture() {
  local outfile="$1"
  shift
  {
    printf 'command:'
    printf ' %q' adb "$@"
    printf '\n\n'
    timeout 45 adb "$@"
  } >"${outfile}" 2>&1 || true
}

adb_shell_capture() {
  local outfile="$1"
  shift
  {
    printf 'command:'
    printf ' %q' adb shell "$@"
    printf '\n\n'
    timeout 45 adb shell "$@"
  } >"${outfile}" 2>&1 || true
}

trim_file_payload() {
  local file="$1"
  sed '1,/^$/d' "${file}" | sed '/^[[:space:]]*$/d'
}

first_payload_line() {
  local file="$1"
  trim_file_payload "${file}" | head -n 1 | tr -d '\r'
}

manual_answer() {
  local check_id="$1"
  local check_text="$2"
  local answer="unknown"
  local note=""

  if [[ -t 0 ]]; then
    printf '\n[manual baseline] %s\n' "${check_text}"
    printf 'Answer y, n, or u for unknown: '
    read -r answer || answer="unknown"
    case "${answer}" in
      y|Y|yes|YES|Yes) answer="yes" ;;
      n|N|no|NO|No) answer="no" ;;
      u|U|unknown|UNKNOWN|Unknown|"") answer="unknown" ;;
      *) answer="unknown" ;;
    esac
    printf 'Optional note, press Enter to skip: '
    read -r note || note=""
  fi

  printf '%s\t%s\t%s\t%s\n' "${check_id}" "${check_text}" "${answer}" "${note}" >>"${PRIVATE_DIR}/manual-baseline.tsv"
}

render_manual_markdown_rows() {
  awk -F '\t' 'NR > 1 { gsub(/\|/, "\\|", $2); gsub(/\|/, "\\|", $4); printf "| `%s` | %s | `%s` | %s |\n", $1, $2, $3, $4 }' "${PRIVATE_DIR}/manual-baseline.tsv"
}

need_command adb
need_command timeout
need_command tar
need_command sha256sum
need_command awk
need_command sed
need_command grep
need_command git

cd "${REPO_ROOT}" || fail "cannot enter repo root: ${REPO_ROOT}"

log "creating read-only Step 32 evidence in ${PRIVATE_DIR}"

cat >"${PRIVATE_DIR}/safety-boundary.txt" <<EOF_SAFETY
Step 32 safety boundary

Target package: ${PKG}

This step is evidence collection only.

Not approved and not performed:
- bootloader unlock
- flashing
- userdata erase
- downgrade
- DSU installation
- Google application sideloading
- Xiaomi flash script execution
- relock
- package uninstall
- package disable
- package restore command execution
- package data clearing
- app force-stop
- settings mutation
EOF_SAFETY

cat >"${PRIVATE_DIR}/host-baseline.txt" <<EOF_HOST
host_timestamp: $(date -Is)
repo_root: ${REPO_ROOT}
repo_head: $(git rev-parse HEAD 2>/dev/null || printf 'unknown')
repo_branch: $(git branch --show-current 2>/dev/null || printf 'unknown')
script: scripts/step32-clean-stock-analytics-prechange-phone-baseline.sh
EOF_HOST

adb_capture "${PRIVATE_DIR}/adb-version.txt" version
adb_capture "${PRIVATE_DIR}/adb-devices.txt" devices -l
adb_capture "${PRIVATE_DIR}/adb-get-state.txt" get-state

ADB_STATE="$(first_payload_line "${PRIVATE_DIR}/adb-get-state.txt")"
[[ "${ADB_STATE}" == "device" ]] || fail "adb state is not device, see ${PRIVATE_DIR}/adb-get-state.txt"

adb_shell_capture "${PRIVATE_DIR}/device-selected-getprop.txt" 'printf "ro.product.device=%s\n" "$(getprop ro.product.device)"; printf "ro.product.model=%s\n" "$(getprop ro.product.model)"; printf "ro.product.manufacturer=%s\n" "$(getprop ro.product.manufacturer)"; printf "ro.build.version.release=%s\n" "$(getprop ro.build.version.release)"; printf "ro.build.version.security_patch=%s\n" "$(getprop ro.build.version.security_patch)"; printf "ro.build.version.incremental=%s\n" "$(getprop ro.build.version.incremental)"; printf "ro.build.fingerprint=%s\n" "$(getprop ro.build.fingerprint)"; printf "ro.boot.verifiedbootstate=%s\n" "$(getprop ro.boot.verifiedbootstate)"; printf "ro.boot.vbmeta.device_state=%s\n" "$(getprop ro.boot.vbmeta.device_state)"; printf "ro.boot.flash.locked=%s\n" "$(getprop ro.boot.flash.locked)"'
adb_shell_capture "${PRIVATE_DIR}/boot-state.txt" 'printf "sys.boot_completed=%s\n" "$(getprop sys.boot_completed)"; printf "dev.bootcomplete=%s\n" "$(getprop dev.bootcomplete)"; printf "init.svc.bootanim=%s\n" "$(getprop init.svc.bootanim)"'
adb_shell_capture "${PRIVATE_DIR}/package-list-user0.txt" "pm list packages --user 0 | grep -F 'package:${PKG}' || true"
adb_shell_capture "${PRIVATE_DIR}/package-disabled-user0.txt" "pm list packages -d --user 0 | grep -F 'package:${PKG}' || true"
adb_shell_capture "${PRIVATE_DIR}/package-path.txt" "pm path ${PKG} || true"
adb_shell_capture "${PRIVATE_DIR}/package-dumpsys.txt" "dumpsys package ${PKG} || true"
adb_shell_capture "${PRIVATE_DIR}/package-installer-record.txt" "cmd package list packages -i --user 0 | grep -F 'package:${PKG}' || true"
adb_shell_capture "${PRIVATE_DIR}/package-user0-record.txt" "dumpsys package ${PKG} | sed -n '/User 0:/,/User /p' | head -n 80 || true"
adb_capture "${PRIVATE_DIR}/logcat-tail-private.txt" logcat -d -t 2000

printf 'check_id\tcheck\tanswer\tnote\n' >"${PRIVATE_DIR}/manual-baseline.tsv"
manual_answer "boot" "boot completes normally"
manual_answer "lockscreen" "lock screen unlocks normally"
manual_answer "touchscreen" "touchscreen works"
manual_answer "launcher" "launcher opens"
manual_answer "settings" "settings opens"
manual_answer "phone" "phone app opens"
manual_answer "sms" "SMS app opens"
manual_answer "wifi" "Wi-Fi works or state is unchanged"
manual_answer "mobile_data" "mobile data works or state is unchanged"
manual_answer "camera" "camera opens"
manual_answer "play_store" "Play Store opens"
manual_answer "browser" "Chrome or WebView-backed browsing works"
manual_answer "notifications" "notifications are not obviously broken"
manual_answer "crash_dialogs" "no repeated crash dialogs are visible"

PACKAGE_PRESENT_FOR_USER0="no"
if trim_file_payload "${PRIVATE_DIR}/package-list-user0.txt" | grep -Fx "package:${PKG}" >/dev/null 2>&1; then
  PACKAGE_PRESENT_FOR_USER0="yes"
fi

PACKAGE_DISABLED_FOR_USER0="no"
if trim_file_payload "${PRIVATE_DIR}/package-disabled-user0.txt" | grep -Fx "package:${PKG}" >/dev/null 2>&1; then
  PACKAGE_DISABLED_FOR_USER0="yes"
fi

PACKAGE_ENABLED_FOR_USER0="no"
if [[ "${PACKAGE_PRESENT_FOR_USER0}" == "yes" && "${PACKAGE_DISABLED_FOR_USER0}" == "no" ]]; then
  PACKAGE_ENABLED_FOR_USER0="yes"
fi

PACKAGE_PATH_STATE="unknown"
if trim_file_payload "${PRIVATE_DIR}/package-path.txt" | grep -E '^package:' >/dev/null 2>&1; then
  PACKAGE_PATH_STATE="present"
elif trim_file_payload "${PRIVATE_DIR}/package-path.txt" | grep -E 'not found|Unknown package|Failure' >/dev/null 2>&1; then
  PACKAGE_PATH_STATE="not_found"
fi

BOOT_COMPLETED="unknown"
if grep -E '^sys\.boot_completed=1$' "${PRIVATE_DIR}/boot-state.txt" >/dev/null 2>&1; then
  BOOT_COMPLETED="yes"
elif grep -E '^sys\.boot_completed=0$' "${PRIVATE_DIR}/boot-state.txt" >/dev/null 2>&1; then
  BOOT_COMPLETED="no"
fi

FATAL_EXCEPTION_COUNT="$(grep -Eic 'FATAL EXCEPTION|AndroidRuntime' "${PRIVATE_DIR}/logcat-tail-private.txt" || true)"
ANALYTICS_LOG_REFERENCE_COUNT="$(grep -Fic "${PKG}" "${PRIVATE_DIR}/logcat-tail-private.txt" || true)"
MANUAL_YES_COUNT="$(awk -F '\t' 'NR > 1 && $3 == "yes" { c++ } END { print c + 0 }' "${PRIVATE_DIR}/manual-baseline.tsv")"
MANUAL_NO_COUNT="$(awk -F '\t' 'NR > 1 && $3 == "no" { c++ } END { print c + 0 }' "${PRIVATE_DIR}/manual-baseline.tsv")"
MANUAL_UNKNOWN_COUNT="$(awk -F '\t' 'NR > 1 && $3 == "unknown" { c++ } END { print c + 0 }' "${PRIVATE_DIR}/manual-baseline.tsv")"

cat >"${PRIVATE_DIR}/planned-commands.txt" <<EOF_COMMANDS
Restore command, planned only, not executed:
adb shell cmd package install-existing --user 0 ${PKG}

Future removal command, not approved and not executed:
# adb shell pm uninstall --user 0 ${PKG}
EOF_COMMANDS

cat >"${PRIVATE_DIR}/status-summary.txt" <<EOF_SUMMARY
step: 32
package: ${PKG}
run_id: ${RUN_ID}
safety_boundary: no package modification performed
adb_state: ${ADB_STATE}
boot_completed: ${BOOT_COMPLETED}
package_present_for_user0: ${PACKAGE_PRESENT_FOR_USER0}
package_enabled_for_user0: ${PACKAGE_ENABLED_FOR_USER0}
package_disabled_for_user0: ${PACKAGE_DISABLED_FOR_USER0}
package_path_state: ${PACKAGE_PATH_STATE}
manual_yes_count: ${MANUAL_YES_COUNT}
manual_no_count: ${MANUAL_NO_COUNT}
manual_unknown_count: ${MANUAL_UNKNOWN_COUNT}
logcat_tail_fatal_exception_count: ${FATAL_EXCEPTION_COUNT}
logcat_tail_analytics_reference_count: ${ANALYTICS_LOG_REFERENCE_COUNT}
restore_command_planned_only: adb shell cmd package install-existing --user 0 ${PKG}
future_removal_command_not_approved: adb shell pm uninstall --user 0 ${PKG}
EOF_SUMMARY

cat >"${PRIVATE_DIR}/package-baseline.txt" <<EOF_PACKAGE
package: ${PKG}
package_present_for_user0: ${PACKAGE_PRESENT_FOR_USER0}
package_enabled_for_user0: ${PACKAGE_ENABLED_FOR_USER0}
package_disabled_for_user0: ${PACKAGE_DISABLED_FOR_USER0}
package_path_state: ${PACKAGE_PATH_STATE}
EOF_PACKAGE

cp "${PRIVATE_DIR}/safety-boundary.txt" "${SHARE_DIR}/safety-boundary.txt"
cp "${PRIVATE_DIR}/status-summary.txt" "${SHARE_DIR}/status-summary.txt"
cp "${PRIVATE_DIR}/package-baseline.txt" "${SHARE_DIR}/package-baseline.txt"
cp "${PRIVATE_DIR}/manual-baseline.tsv" "${SHARE_DIR}/manual-baseline.tsv"
cp "${PRIVATE_DIR}/planned-commands.txt" "${SHARE_DIR}/planned-commands.txt"

cat >"${SHARE_DIR}/README.md" <<EOF_README
# Step 32 shareable summary

This bundle records the clean-stock pre-change phone baseline for \`${PKG}\`.

It is a shareable summary only. Private raw files, including the private logcat snapshot and full package dump, remain under:

\`evidence/private/citrine-clean-stock-analytics-prechange-phone-baseline-${RUN_ID}/\`

No package uninstall, package disable, package restore command, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was performed.
EOF_README

(
  cd "${SHARE_DIR}"
  sha256sum README.md safety-boundary.txt status-summary.txt package-baseline.txt manual-baseline.tsv planned-commands.txt > SHA256SUMS
)

(
  cd "${PRIVATE_DIR}"
  tar -czf "${BUNDLE_PATH}" shareable-summary
)

BUNDLE_SHA256="$(sha256sum "${BUNDLE_PATH}" | awk '{print $1}')"
BUNDLE_SIZE="$(stat -c '%s' "${BUNDLE_PATH}")"

MANUAL_ROWS="$(render_manual_markdown_rows)"

cat >"${DOC_PATH}" <<EOF_DOC
# Clean Stock Analytics Prechange Phone Baseline, ${DOC_DATE_TITLE}

## Current status

Step 32 collected a pre-change phone baseline for:

\`\`\`text
${PKG}
\`\`\`

This is still evidence collection and planning only.

No package removal, package disablement, restore command execution, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock was approved or performed.

## Evidence bundle

\`\`\`text
${BUNDLE_NAME}
\`\`\`

## Baseline result

\`\`\`text
adb_state: ${ADB_STATE}
boot_completed: ${BOOT_COMPLETED}
package_present_for_user0: ${PACKAGE_PRESENT_FOR_USER0}
package_enabled_for_user0: ${PACKAGE_ENABLED_FOR_USER0}
package_disabled_for_user0: ${PACKAGE_DISABLED_FOR_USER0}
package_path_state: ${PACKAGE_PATH_STATE}
manual_yes_count: ${MANUAL_YES_COUNT}
manual_no_count: ${MANUAL_NO_COUNT}
manual_unknown_count: ${MANUAL_UNKNOWN_COUNT}
logcat_tail_fatal_exception_count: ${FATAL_EXCEPTION_COUNT}
logcat_tail_analytics_reference_count: ${ANALYTICS_LOG_REFERENCE_COUNT}
\`\`\`

## Manual phone baseline

| ID | Check | Result | Note |
| --- | --- | --- | --- |
${MANUAL_ROWS}

## Restore-first rule

The restore command remains documented before any future removal command is considered.

Restore command, planned only:

\`\`\`text
adb shell cmd package install-existing --user 0 ${PKG}
\`\`\`

Future removal command, not approved:

\`\`\`text
adb shell pm uninstall --user 0 ${PKG}
\`\`\`

## Safety boundary

Step 32 does not approve execution of either the future removal command or the restore command.

## Current conclusion

The project now has a pre-change phone baseline for ${PKG}.

The next step is Step 33, a controlled one-package test gate for ${PKG}. Step 33 must not be executed unless this Step 32 baseline shows no manual failures and the package remains present, enabled, and restorable by plan.
EOF_DOC

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  cat >"${MANIFEST_PATH}" <<EOF_MANIFEST
# Evidence Bundle Manifest

Generated: $(date -Is)

| SHA256 | Size bytes | Bundle |
| --- | ---: | --- |
EOF_MANIFEST
else
  tmp_manifest="${MANIFEST_PATH}.tmp"
  awk -v generated="Generated: $(date -Is)" '
    NR == 1 { print; next }
    /^Generated:/ { print generated; next }
    { print }
  ' "${MANIFEST_PATH}" >"${tmp_manifest}"
  mv "${tmp_manifest}" "${MANIFEST_PATH}"
fi

printf '| `%s` | %s | `%s` |\n' "${BUNDLE_SHA256}" "${BUNDLE_SIZE}" "${BUNDLE_NAME}" >>"${MANIFEST_PATH}"

log "wrote private evidence: ${PRIVATE_DIR}"
log "wrote shareable bundle: ${BUNDLE_PATH}"
log "wrote status document: ${DOC_PATH}"
log "updated manifest: ${MANIFEST_PATH}"
log "Step 32 complete, no Android package state was modified"

cat <<EOF_DONE

Step 32 output files:
  ${DOC_PATH}
  ${BUNDLE_PATH}
  ${MANIFEST_PATH}

Next local verification command:
  cd ${REPO_ROOT}
  git status --short
  sed -n '1,260p' ${DOC_PATH}
  grep '${BUNDLE_NAME}' ${MANIFEST_PATH} || true
EOF_DONE
