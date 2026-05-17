#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="/home/foo/Workspace/android-rom-dev"
PACKAGE_NAME="com.miui.analytics"
STEP_NAME="clean-stock-analytics-one-package-test"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
PRIVATE_ROOT="${HOME}/android-rom-dev-private-evidence"
PRIVATE_DIR="${PRIVATE_ROOT}/citrine-${STEP_NAME}-${RUN_ID}"
SHAREABLE_DIR="${PRIVATE_DIR}/shareable-summary"
BUNDLE_DIR="${REPO_ROOT}/evidence/bundles"
DOC_DIR="${REPO_ROOT}/docs/13-clean-stock-feasibility"
MANIFEST="${REPO_ROOT}/evidence/manifests/evidence-bundles.md"
DOC_FILE="${DOC_DIR}/clean-stock-analytics-one-package-test-2026-05-17.md"
BUNDLE_FILE="${BUNDLE_DIR}/citrine-${STEP_NAME}-${RUN_ID}-shareable-summary.tar.gz"
APPROVAL_PHRASE="approve step 33 com.miui.analytics user0 uninstall"
RESTORE_COMMAND="adb shell cmd package install-existing --user 0 ${PACKAGE_NAME}"
UNINSTALL_COMMAND="adb shell pm uninstall --user 0 ${PACKAGE_NAME}"

mkdir -p "${PRIVATE_DIR}" "${SHAREABLE_DIR}" "${BUNDLE_DIR}" "${DOC_DIR}" "$(dirname "${MANIFEST}")"

log() {
  printf '[step33] %s\n' "$*"
}

run_to_file() {
  local output_file="$1"
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
    set +e
    "$@"
    local rc="$?"
    set -e
    printf '\nexit_code: %s\n' "${rc}"
  } > "${output_file}" 2>&1
}

file_has_package_line() {
  local file="$1"
  grep -F "package:${PACKAGE_NAME}" "${file}" >/dev/null 2>&1
}

normalize_boot_completed() {
  local raw="$1"
  case "${raw}" in
    1|yes|true|TRUE|True) printf 'yes' ;;
    0|no|false|FALSE|False|'') printf 'no' ;;
    *) printf 'unknown' ;;
  esac
}

state_value() {
  local key="$1"
  local file="$2"
  awk -F': ' -v k="${key}" '$1 == k { print $2; exit }' "${file}"
}

collect_state() {
  local prefix="$1"
  local out_file="$2"
  local adb_state_raw boot_raw boot_completed present enabled disabled path_state fatal_count analytics_count dumpsys_user0_installed dumpsys_user0_enabled
  local state_dir="${PRIVATE_DIR}/${prefix}-raw"

  mkdir -p "${state_dir}"

  set +e
  adb get-state 2>&1 | tr -d '\r' > "${state_dir}/adb-state.txt"
  adb shell getprop sys.boot_completed 2>&1 | tr -d '\r' > "${state_dir}/boot-completed.txt"
  adb shell pm list packages --user 0 2>&1 | tr -d '\r' > "${state_dir}/pm-list-packages-user0.txt"
  adb shell pm list packages -e --user 0 2>&1 | tr -d '\r' > "${state_dir}/pm-list-packages-enabled-user0.txt"
  adb shell pm list packages -d --user 0 2>&1 | tr -d '\r' > "${state_dir}/pm-list-packages-disabled-user0.txt"
  adb shell pm path "${PACKAGE_NAME}" 2>&1 | tr -d '\r' > "${state_dir}/pm-path.txt"
  adb logcat -d -t 400 2>&1 | tr -d '\r' > "${state_dir}/logcat-tail-400.txt"
  adb shell dumpsys package "${PACKAGE_NAME}" 2>&1 | tr -d '\r' > "${state_dir}/dumpsys-package.txt"
  set -e

  adb_state_raw="$(head -n 1 "${state_dir}/adb-state.txt" | sed 's/[[:space:]]*$//' || true)"
  boot_raw="$(head -n 1 "${state_dir}/boot-completed.txt" | sed 's/[[:space:]]*$//' || true)"
  boot_completed="$(normalize_boot_completed "${boot_raw}")"

  if file_has_package_line "${state_dir}/pm-list-packages-user0.txt"; then
    present="yes"
  else
    present="no"
  fi

  if file_has_package_line "${state_dir}/pm-list-packages-enabled-user0.txt"; then
    enabled="yes"
  else
    enabled="no"
  fi

  if file_has_package_line "${state_dir}/pm-list-packages-disabled-user0.txt"; then
    disabled="yes"
  else
    disabled="no"
  fi

  if grep -F "package:" "${state_dir}/pm-path.txt" >/dev/null 2>&1; then
    path_state="present"
  else
    path_state="unknown"
  fi

  if awk '/User 0:/ && /installed=true/ { found=1 } END { exit found ? 0 : 1 }' "${state_dir}/dumpsys-package.txt"; then
    dumpsys_user0_installed="yes"
  else
    dumpsys_user0_installed="no"
  fi

  if awk '/User 0:/ && /enabled=0/ { found=1 } END { exit found ? 0 : 1 }' "${state_dir}/dumpsys-package.txt"; then
    dumpsys_user0_enabled="yes"
  else
    dumpsys_user0_enabled="no"
  fi

  fatal_count="$(grep -ic 'FATAL EXCEPTION' "${state_dir}/logcat-tail-400.txt" || true)"
  analytics_count="$(grep -ic "${PACKAGE_NAME}" "${state_dir}/logcat-tail-400.txt" || true)"

  cat > "${out_file}" <<STATE
${prefix}_adb_state: ${adb_state_raw:-unknown}
${prefix}_boot_completed_raw: ${boot_raw:-unknown}
${prefix}_boot_completed: ${boot_completed}
${prefix}_package_present_for_user0: ${present}
${prefix}_package_enabled_for_user0: ${enabled}
${prefix}_package_disabled_for_user0: ${disabled}
${prefix}_package_path_state: ${path_state}
${prefix}_dumpsys_user0_installed: ${dumpsys_user0_installed}
${prefix}_dumpsys_user0_enabled_default: ${dumpsys_user0_enabled}
${prefix}_logcat_tail_fatal_exception_count: ${fatal_count}
${prefix}_logcat_tail_analytics_reference_count: ${analytics_count}
STATE
}

ask_check() {
  local check_id="$1"
  local check_text="$2"
  local answer note

  while true; do
    printf '\n[post-change phone check] %s\n' "${check_text}"
    read -r -p 'Answer y, n, or u for unknown: ' answer
    case "${answer}" in
      y|Y) answer="yes"; break ;;
      n|N) answer="no"; break ;;
      u|U) answer="unknown"; break ;;
      *) printf 'Please answer y, n, or u.\n' ;;
    esac
  done

  read -r -p 'Optional note, press Enter to skip: ' note
  printf '%s\t%s\t%s\t%s\n' "${check_id}" "${check_text}" "${answer}" "${note}" >> "${PRIVATE_DIR}/post-change-manual-checks.tsv"
}

manual_result_counts() {
  awk -F'\t' '
    NR > 1 {
      if ($3 == "unknown") unknown++
      else if ($1 == "unexpected_reboot" && $3 == "yes") failure++
      else if ($1 == "unexpected_reboot" && $3 == "no") healthy++
      else if ($1 != "unexpected_reboot" && $3 == "yes") healthy++
      else if ($1 != "unexpected_reboot" && $3 == "no") failure++
    }
    END {
      printf "post_manual_healthy_count: %d\n", healthy + 0
      printf "post_manual_failure_count: %d\n", failure + 0
      printf "post_manual_unknown_count: %d\n", unknown + 0
    }
  ' "${PRIVATE_DIR}/post-change-manual-checks.tsv"
}

manual_failure_count() {
  awk -F'\t' '
    NR > 1 {
      if ($1 == "unexpected_reboot" && $3 == "yes") failures++
      else if ($1 != "unexpected_reboot" && $3 == "no") failures++
    }
    END { print failures + 0 }
  ' "${PRIVATE_DIR}/post-change-manual-checks.tsv"
}

manual_unknown_count() {
  awk -F'\t' 'NR > 1 && $3 == "unknown" { count++ } END { print count + 0 }' "${PRIVATE_DIR}/post-change-manual-checks.tsv"
}

write_safety_boundary() {
  cat > "${SHAREABLE_DIR}/safety-boundary.txt" <<BOUNDARY
Step 33 safety boundary

Target package: ${PACKAGE_NAME}

This step is a controlled one-package user 0 test.

Allowed only after exact typed approval:
- ${UNINSTALL_COMMAND}

Allowed only as break-glass restoration if post-change checks fail:
- ${RESTORE_COMMAND}

Expected healthy package result after uninstall:
- package is absent for Android user 0
- phone remains booted and usable
- pm path may be unavailable after user 0 uninstall and is not by itself a failure

Not approved and not performed:
- bootloader unlock
- flashing
- userdata erase
- downgrade
- DSU installation
- Google application sideloading
- Xiaomi flash script execution
- relock
- package disable
- package data clearing
- app force-stop
- settings mutation
- any package command for any package other than ${PACKAGE_NAME}
BOUNDARY
}

write_host_baseline() {
  cat > "${SHAREABLE_DIR}/host-baseline.txt" <<HOST
host_timestamp: $(date -Is)
repo_root: ${REPO_ROOT}
private_root: ${PRIVATE_ROOT}
repo_head: $(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || printf 'unknown')
repo_branch: $(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || printf 'unknown')
script: scripts/step33-clean-stock-analytics-one-package-test.sh
script_version: step33-v3-accept-user0-removal-path-unknown
HOST
}

write_exact_command_set() {
  cat > "${SHAREABLE_DIR}/exact-command-set.txt" <<COMMANDS
pre-change package check:
adb shell pm list packages --user 0 | grep -F 'package:${PACKAGE_NAME}' || true
adb shell pm list packages -e --user 0 | grep -F 'package:${PACKAGE_NAME}' || true
adb shell pm path ${PACKAGE_NAME} || true

restore command, available before removal:
${RESTORE_COMMAND}

approved change command, executes only after exact typed approval:
${UNINSTALL_COMMAND}

post-change package check:
adb shell pm list packages --user 0 | grep -F 'package:${PACKAGE_NAME}' || true
adb shell pm path ${PACKAGE_NAME} || true

restore command if anything breaks:
${RESTORE_COMMAND}
COMMANDS
}

write_readme() {
  local final_result="$1"
  cat > "${SHAREABLE_DIR}/README.txt" <<README
Step 33 shareable summary

Target package: ${PACKAGE_NAME}
Final result: ${final_result}

This summary excludes private full logcat and full dumpsys output. Raw private evidence was stored outside the repository.
README
}

copy_shareable_files() {
  cp "${PRIVATE_DIR}/pre-change-summary.txt" "${SHAREABLE_DIR}/pre-change-summary.txt"
  cp "${PRIVATE_DIR}/post-change-summary.txt" "${SHAREABLE_DIR}/post-change-summary.txt" 2>/dev/null || true
  cp "${PRIVATE_DIR}/manual-counts.txt" "${SHAREABLE_DIR}/manual-counts.txt" 2>/dev/null || true
  cp "${PRIVATE_DIR}/post-change-manual-checks.tsv" "${SHAREABLE_DIR}/post-change-manual-checks.tsv" 2>/dev/null || true
  cp "${PRIVATE_DIR}/uninstall-result.txt" "${SHAREABLE_DIR}/uninstall-result.txt" 2>/dev/null || true
  cp "${PRIVATE_DIR}/restore-result.txt" "${SHAREABLE_DIR}/restore-result.txt" 2>/dev/null || true
  cp "${PRIVATE_DIR}/restore-summary.txt" "${SHAREABLE_DIR}/restore-summary.txt" 2>/dev/null || true
}

make_shareable_bundle() {
  copy_shareable_files
  cat > "${SHAREABLE_DIR}/final-status.txt" <<STATUS
final_result: ${FINAL_RESULT}
restore_executed: ${RESTORE_EXECUTED}
restore_reason: ${RESTORE_REASON}
STATUS
  (
    cd "${SHAREABLE_DIR}"
    sha256sum ./* > SHA256SUMS
  )
  tar -C "${PRIVATE_DIR}" -czf "${BUNDLE_FILE}" shareable-summary
}

write_manifest_entry() {
  local bundle_name bundle_hash bundle_size
  bundle_name="$(basename "${BUNDLE_FILE}")"
  bundle_hash="$(sha256sum "${BUNDLE_FILE}" | awk '{print $1}')"
  bundle_size="$(stat -c '%s' "${BUNDLE_FILE}")"

  if [[ ! -f "${MANIFEST}" ]]; then
    cat > "${MANIFEST}" <<MANIFEST_HEADER
# Evidence Bundle Manifest

Generated: $(date -Is)

| SHA256 | Size bytes | Bundle |
| --- | ---: | --- |
MANIFEST_HEADER
  fi

  if ! grep -F "${bundle_name}" "${MANIFEST}" >/dev/null 2>&1; then
    printf '| `%s` | %s | `%s` |\n' "${bundle_hash}" "${bundle_size}" "${bundle_name}" >> "${MANIFEST}"
  fi
}

write_status_doc() {
  local final_result="$1"
  local restore_executed="$2"
  local restore_reason="$3"
  local bundle_name
  bundle_name="$(basename "${BUNDLE_FILE}")"

  cat > "${DOC_FILE}" <<DOC
# Clean Stock Analytics One-Package Test, 2026-05-17

## Current status

Step 33 executed the approved one-package user 0 test for:

\`\`\`text
${PACKAGE_NAME}
\`\`\`

The test used this exact approved command:

\`\`\`text
${UNINSTALL_COMMAND}
\`\`\`

The restore command was documented before the package change:

\`\`\`text
${RESTORE_COMMAND}
\`\`\`

## Evidence bundle

\`\`\`text
${bundle_name}
\`\`\`

## Pre-change result

\`\`\`text
$(cat "${PRIVATE_DIR}/pre-change-summary.txt")
\`\`\`

## Post-change result

\`\`\`text
$(cat "${PRIVATE_DIR}/post-change-summary.txt")
\`\`\`

## Manual post-change checks

\`\`\`text
$(cat "${PRIVATE_DIR}/manual-counts.txt")
\`\`\`

## Restore result

\`\`\`text
restore_executed: ${restore_executed}
restore_reason: ${restore_reason}
$(if [[ -f "${PRIVATE_DIR}/restore-summary.txt" ]]; then cat "${PRIVATE_DIR}/restore-summary.txt"; fi)
\`\`\`

## Important package-state interpretation

After \`pm uninstall --user 0\`, \`pm path ${PACKAGE_NAME}\` may be unavailable for the current user context. This is not treated as failure when the package is absent for Android user 0, the phone remains booted, the manual checks pass, and the restore command was already documented before removal.

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package disable, package data clearing, app force-stop, or settings mutation was approved or performed.

## Current conclusion

\`\`\`text
final_result: ${final_result}
\`\`\`

If the final result is \`package_removed_user0_phone_healthy\`, then \`${PACKAGE_NAME}\` was removed only for Android user 0 and the phone remained healthy after the package change.
DOC
}

main() {
  if [[ ! -d "${REPO_ROOT}/.git" ]]; then
    printf 'ERROR: repo root missing or not a git repository: %s\n' "${REPO_ROOT}" >&2
    exit 1
  fi

  if ! command -v adb >/dev/null 2>&1; then
    printf 'ERROR: adb not found in PATH.\n' >&2
    exit 1
  fi

  log "creating Step 33 evidence in ${PRIVATE_DIR}"
  write_safety_boundary
  write_host_baseline
  write_exact_command_set

  run_to_file "${PRIVATE_DIR}/adb-devices.txt" adb devices
  collect_state pre "${PRIVATE_DIR}/pre-change-summary.txt"

  local pre_adb pre_boot pre_present pre_enabled pre_path
  pre_adb="$(state_value pre_adb_state "${PRIVATE_DIR}/pre-change-summary.txt")"
  pre_boot="$(state_value pre_boot_completed "${PRIVATE_DIR}/pre-change-summary.txt")"
  pre_present="$(state_value pre_package_present_for_user0 "${PRIVATE_DIR}/pre-change-summary.txt")"
  pre_enabled="$(state_value pre_package_enabled_for_user0 "${PRIVATE_DIR}/pre-change-summary.txt")"
  pre_path="$(state_value pre_package_path_state "${PRIVATE_DIR}/pre-change-summary.txt")"

  if [[ "${pre_adb}" != "device" || "${pre_boot}" != "yes" || "${pre_present}" != "yes" || "${pre_enabled}" != "yes" || "${pre_path}" != "present" ]]; then
    printf 'ERROR: pre-change package state is not suitable for Step 33.\n' >&2
    cat "${PRIVATE_DIR}/pre-change-summary.txt" >&2
    printf '\nRaw package files are in: %s/pre-raw\n' "${PRIVATE_DIR}" >&2
    exit 1
  fi

  cat <<INTRO

Step 33 exact command set

Target package:
  ${PACKAGE_NAME}

Restore command available before removal:
  ${RESTORE_COMMAND}

One package change command:
  ${UNINSTALL_COMMAND}

This script will not continue unless you type this exact approval phrase:
  ${APPROVAL_PHRASE}

Important manual check wording:
  If the phone did not reboot, answer "n" to "unexpected reboot occurred".

INTRO

  local approval
  read -r -p 'Type exact approval phrase now, or press Enter to abort: ' approval

  if [[ "${approval}" != "${APPROVAL_PHRASE}" ]]; then
    log "approval phrase not provided, aborting before package change"
    exit 0
  fi

  log "executing approved one-package user 0 uninstall command"
  set +e
  uninstall_output="$(adb shell pm uninstall --user 0 "${PACKAGE_NAME}" 2>&1 | tr -d '\r')"
  uninstall_exit_code="$?"
  set -e

  cat > "${PRIVATE_DIR}/uninstall-result.txt" <<UNINSTALL
uninstall_exit_code: ${uninstall_exit_code}
uninstall_output: ${uninstall_output}
UNINSTALL

  sleep 2
  collect_state post "${PRIVATE_DIR}/post-change-summary.txt"

  printf 'check_id\tcheck\tanswer\tnote\n' > "${PRIVATE_DIR}/post-change-manual-checks.tsv"

  cat <<CHECKS

Now check the phone in its current state. The phone is not expected to reboot.
Answer the following checks based on what you can verify now.

For the first question:
  answer n if the phone did not reboot
  answer y only if an unexpected reboot occurred

CHECKS

  ask_check unexpected_reboot 'unexpected reboot occurred'
  ask_check lockscreen 'lock screen unlocks normally, or remains unlockable if already unlocked'
  ask_check touchscreen 'touchscreen works'
  ask_check launcher 'launcher opens'
  ask_check settings 'settings opens'
  ask_check phone 'phone app opens'
  ask_check sms 'SMS app opens'
  ask_check wifi 'Wi-Fi works or state is unchanged'
  ask_check mobile_data 'mobile data works or state is unchanged'
  ask_check camera 'camera opens'
  ask_check play_store 'Play Store opens'
  ask_check browser 'Chrome or WebView-backed browsing works'
  ask_check notifications 'notifications are not obviously broken'
  ask_check crash_dialogs 'no repeated crash dialogs are visible'

  manual_result_counts > "${PRIVATE_DIR}/manual-counts.txt"

  local failures unknowns post_boot post_present
  failures="$(manual_failure_count)"
  unknowns="$(manual_unknown_count)"
  post_boot="$(state_value post_boot_completed "${PRIVATE_DIR}/post-change-summary.txt")"
  post_present="$(state_value post_package_present_for_user0 "${PRIVATE_DIR}/post-change-summary.txt")"

  RESTORE_EXECUTED="no"
  RESTORE_REASON="not_needed"
  FINAL_RESULT="package_removed_user0_phone_healthy"

  if [[ "${uninstall_exit_code}" != "0" ]]; then
    RESTORE_EXECUTED="no"
    RESTORE_REASON="uninstall_failed_no_restore_needed"
    FINAL_RESULT="uninstall_failed"
  elif [[ "${post_boot}" != "yes" ]]; then
    RESTORE_EXECUTED="yes"
    RESTORE_REASON="boot_completed_not_confirmed"
    FINAL_RESULT="restored_after_post_change_failure"
  elif [[ "${failures}" != "0" ]]; then
    RESTORE_EXECUTED="yes"
    RESTORE_REASON="manual_phone_check_failed"
    FINAL_RESULT="restored_after_post_change_failure"
  elif [[ "${post_present}" != "no" ]]; then
    RESTORE_EXECUTED="yes"
    RESTORE_REASON="package_still_present_for_user0_after_uninstall"
    FINAL_RESULT="restored_after_unexpected_package_state"
  elif [[ "${unknowns}" != "0" ]]; then
    RESTORE_EXECUTED="no"
    RESTORE_REASON="not_needed_manual_unknowns_recorded"
    FINAL_RESULT="package_removed_user0_with_manual_unknowns"
  fi

  if [[ "${RESTORE_EXECUTED}" == "yes" ]]; then
    log "post-change failure detected, executing restore command"
    set +e
    restore_output="$(adb shell cmd package install-existing --user 0 "${PACKAGE_NAME}" 2>&1 | tr -d '\r')"
    restore_exit_code="$?"
    set -e

    cat > "${PRIVATE_DIR}/restore-result.txt" <<RESTORE
restore_exit_code: ${restore_exit_code}
restore_output: ${restore_output}
RESTORE

    sleep 2
    collect_state restore "${PRIVATE_DIR}/restore-summary.txt"
  fi

  write_readme "${FINAL_RESULT}"
  write_status_doc "${FINAL_RESULT}" "${RESTORE_EXECUTED}" "${RESTORE_REASON}"
  make_shareable_bundle
  write_manifest_entry

  log "wrote private evidence outside repo: ${PRIVATE_DIR}"
  log "wrote shareable bundle: ${BUNDLE_FILE}"
  log "wrote status document: ${DOC_FILE}"
  log "updated manifest: ${MANIFEST}"
  log "Step 33 complete: ${FINAL_RESULT}"

  cat <<DONE

Step 33 output files:
  ${DOC_FILE}
  ${BUNDLE_FILE}
  ${MANIFEST}

Next local verification command:
  cd ${REPO_ROOT}
  git status --short
  sed -n '1,340p' ${DOC_FILE}
  grep '$(basename "${BUNDLE_FILE}")' ${MANIFEST} || true
DONE
}

main "$@"
