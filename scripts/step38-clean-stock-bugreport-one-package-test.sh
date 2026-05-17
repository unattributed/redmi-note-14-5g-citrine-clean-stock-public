#!/usr/bin/env bash
set -Eeuo pipefail

STEP_ID="38"
PACKAGE_NAME="com.miui.bugreport"
PACKAGE_LABEL="bugreport"
DOC_TITLE="Clean Stock Bugreport One-Package Test"
APPROVAL_PHRASE="approve step 38 com.miui.bugreport user0 uninstall"

REPO_DIR="/home/foo/Workspace/android-rom-dev"
DOC_DIR="${REPO_DIR}/docs/13-clean-stock-feasibility"
BUNDLE_DIR="${REPO_DIR}/evidence/bundles"
MANIFEST="${REPO_DIR}/evidence/manifests/evidence-bundles.md"
PRIVATE_ROOT="${HOME}/android-rom-dev-private-evidence"

STAMP="$(date +%Y%m%d-%H%M%S)"
EVIDENCE_DIR="${PRIVATE_ROOT}/citrine-clean-stock-${PACKAGE_LABEL}-one-package-test-${STAMP}"
SHARE_DIR="${EVIDENCE_DIR}/shareable-summary"
DOC_FILE="${DOC_DIR}/clean-stock-${PACKAGE_LABEL}-one-package-test-2026-05-17.md"
BUNDLE_FILE="${BUNDLE_DIR}/citrine-clean-stock-${PACKAGE_LABEL}-one-package-test-${STAMP}-shareable-summary.tar.gz"

mkdir -p "${EVIDENCE_DIR}" "${SHARE_DIR}" "${DOC_DIR}" "${BUNDLE_DIR}" "$(dirname "${MANIFEST}")"

COMMAND_LOG="${EVIDENCE_DIR}/command-log.txt"
SUMMARY_FILE="${SHARE_DIR}/summary.txt"
PACKAGE_STATE_TSV="${SHARE_DIR}/package-state.tsv"
PHONE_CHECKS_TSV="${SHARE_DIR}/phone-checks.tsv"
RESTORE_COMMANDS_FILE="${SHARE_DIR}/restore-command.txt"
REMOVAL_COMMANDS_FILE="${SHARE_DIR}/removal-command-approved.txt"

log() {
  printf '[step%s] %s\n' "${STEP_ID}" "$*"
}

run_capture() {
  local label="$1"
  shift
  {
    echo "== ${label} =="
    echo "+ $*"
    "$@"
    echo
  } >> "${COMMAND_LOG}" 2>&1
}

adb_shell_raw() {
  adb shell "$@" 2>/dev/null | tr -d '\r' || true
}

normalize_boot_completed() {
  local raw="$1"
  case "${raw}" in
    1|yes|true|TRUE) echo "yes" ;;
    0|no|false|FALSE|"") echo "no" ;;
    *) echo "${raw}" ;;
  esac
}

count_fatal_exceptions() {
  adb logcat -d -t 5000 2>/dev/null | tr -d '\r' | grep -ic 'FATAL EXCEPTION' || true
}

count_package_references() {
  adb logcat -d -t 5000 2>/dev/null | tr -d '\r' | grep -ic "${PACKAGE_NAME}" || true
}

write_package_raw_outputs() {
  local phase="$1"

  adb shell pm list packages --user 0 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-pm-list-packages-user0.txt" || true
  adb shell pm list packages --user 0 "${PACKAGE_NAME}" 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-pm-list-packages-user0-filtered.txt" || true
  adb shell pm list packages -e --user 0 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-pm-list-packages-enabled-user0.txt" || true
  adb shell pm list packages -d --user 0 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-pm-list-packages-disabled-user0.txt" || true
  adb shell pm path "${PACKAGE_NAME}" 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-pm-path.txt" || true
  adb shell dumpsys package "${PACKAGE_NAME}" 2>&1 | tr -d '\r' > "${EVIDENCE_DIR}/${phase}-dumpsys-package.txt" || true
}

package_present_for_user0() {
  local phase="$1"
  if grep -Fxq "package:${PACKAGE_NAME}" "${EVIDENCE_DIR}/${phase}-pm-list-packages-user0-filtered.txt" || \
     grep -Fxq "package:${PACKAGE_NAME}" "${EVIDENCE_DIR}/${phase}-pm-list-packages-user0.txt"; then
    echo "yes"
  else
    echo "no"
  fi
}

package_enabled_for_user0() {
  local phase="$1"
  if grep -Fxq "package:${PACKAGE_NAME}" "${EVIDENCE_DIR}/${phase}-pm-list-packages-enabled-user0.txt"; then
    echo "yes"
  else
    echo "no"
  fi
}

package_disabled_for_user0() {
  local phase="$1"
  if grep -Fxq "package:${PACKAGE_NAME}" "${EVIDENCE_DIR}/${phase}-pm-list-packages-disabled-user0.txt"; then
    echo "yes"
  else
    echo "no"
  fi
}

package_path_state() {
  local phase="$1"
  if grep -Eq '^package:' "${EVIDENCE_DIR}/${phase}-pm-path.txt"; then
    echo "present"
  else
    echo "unknown"
  fi
}

dumpsys_user0_installed() {
  local phase="$1"
  if grep -Eq 'User 0:.*installed=true' "${EVIDENCE_DIR}/${phase}-dumpsys-package.txt"; then
    echo "yes"
  else
    echo "no"
  fi
}

dumpsys_user0_enabled_default() {
  local phase="$1"
  if grep -Eq 'User 0:.*enabled=0' "${EVIDENCE_DIR}/${phase}-dumpsys-package.txt"; then
    echo "yes"
  else
    echo "no"
  fi
}

collect_state() {
  local phase="$1"
  local prefix="$2"

  local adb_state boot_raw boot_norm fatal_count package_ref_count
  adb_state="$(adb get-state 2>/dev/null | tr -d '\r' || true)"
  boot_raw="$(adb_shell_raw getprop sys.boot_completed)"
  boot_norm="$(normalize_boot_completed "${boot_raw}")"

  write_package_raw_outputs "${phase}"

  fatal_count="$(count_fatal_exceptions)"
  package_ref_count="$(count_package_references)"

  eval "${prefix}_adb_state='${adb_state}'"
  eval "${prefix}_boot_completed_raw='${boot_raw}'"
  eval "${prefix}_boot_completed='${boot_norm}'"
  eval "${prefix}_package_present_for_user0='$(package_present_for_user0 "${phase}")'"
  eval "${prefix}_package_enabled_for_user0='$(package_enabled_for_user0 "${phase}")'"
  eval "${prefix}_package_disabled_for_user0='$(package_disabled_for_user0 "${phase}")'"
  eval "${prefix}_package_path_state='$(package_path_state "${phase}")'"
  eval "${prefix}_dumpsys_user0_installed='$(dumpsys_user0_installed "${phase}")'"
  eval "${prefix}_dumpsys_user0_enabled_default='$(dumpsys_user0_enabled_default "${phase}")'"
  eval "${prefix}_logcat_tail_fatal_exception_count='${fatal_count}'"
  eval "${prefix}_logcat_tail_${PACKAGE_LABEL}_reference_count='${package_ref_count}'"
}

ask_check() {
  local key="$1"
  local prompt="$2"
  local answer note

  while true; do
    echo
    echo "[post-change phone check] ${prompt}"
    read -r -p "Answer y, n, or u for unknown: " answer
    case "${answer}" in
      y|Y|n|N|u|U)
        answer="$(echo "${answer}" | tr '[:upper:]' '[:lower:]')"
        break
        ;;
      *)
        echo "Please answer y, n, or u."
        ;;
    esac
  done

  read -r -p "Optional note, press Enter to skip: " note
  printf '%s\t%s\t%s\t%s\n' "${key}" "${prompt}" "${answer}" "${note}" >> "${PHONE_CHECKS_TSV}"
}

manual_checks() {
  printf 'key\tprompt\tanswer\tnote\n' > "${PHONE_CHECKS_TSV}"

  echo
  echo "Now check the phone in its current state. The phone is not expected to reboot."
  echo "Answer the following checks based on what you can verify now."
  echo
  echo "For the first question:"
  echo "  answer n if the phone did not reboot"
  echo "  answer y only if an unexpected reboot occurred"
  echo

  ask_check unexpected_reboot 'unexpected reboot occurred'
  ask_check lock_screen 'lock screen unlocks normally, or remains unlockable if already unlocked'
  ask_check touchscreen 'touchscreen works'
  ask_check launcher 'launcher opens'
  ask_check settings 'settings opens'
  ask_check phone_app 'phone app opens'
  ask_check sms_app 'SMS app opens'
  ask_check wifi 'Wi-Fi works or state is unchanged'
  ask_check mobile_data 'mobile data works or state is unchanged'
  ask_check camera 'camera opens'
  ask_check play_store 'Play Store opens'
  ask_check chrome_webview 'Chrome or WebView-backed browsing works'
  ask_check notifications 'notifications are not obviously broken'
  ask_check crash_dialogs 'no repeated crash dialogs are visible'
}

manual_failure_count() {
  awk -F '\t' '
    NR == 1 { next }
    $1 == "unexpected_reboot" && $3 == "y" { failures++ }
    $1 != "unexpected_reboot" && $3 == "n" { failures++ }
    END { print failures + 0 }
  ' "${PHONE_CHECKS_TSV}"
}

manual_unknown_count() {
  awk -F '\t' 'NR > 1 && $3 == "u" { unknown++ } END { print unknown + 0 }' "${PHONE_CHECKS_TSV}"
}

manual_healthy_count() {
  awk -F '\t' '
    NR == 1 { next }
    $1 == "unexpected_reboot" && $3 == "n" { healthy++ }
    $1 != "unexpected_reboot" && $3 == "y" { healthy++ }
    END { print healthy + 0 }
  ' "${PHONE_CHECKS_TSV}"
}

write_package_state_tsv() {
  {
    printf 'phase\tadb_state\tboot_completed_raw\tboot_completed\tpresent_user0\tenabled_user0\tdisabled_user0\tpath_state\tdumpsys_user0_installed\tdumpsys_user0_enabled_default\tfatal_exception_count\tpackage_reference_count\n'
    printf 'pre\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "${pre_adb_state}" "${pre_boot_completed_raw}" "${pre_boot_completed}" \
      "${pre_package_present_for_user0}" "${pre_package_enabled_for_user0}" "${pre_package_disabled_for_user0}" "${pre_package_path_state}" \
      "${pre_dumpsys_user0_installed}" "${pre_dumpsys_user0_enabled_default}" \
      "${pre_logcat_tail_fatal_exception_count}" "${pre_logcat_tail_bugreport_reference_count}"
    printf 'post\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "${post_adb_state}" "${post_boot_completed_raw}" "${post_boot_completed}" \
      "${post_package_present_for_user0}" "${post_package_enabled_for_user0}" "${post_package_disabled_for_user0}" "${post_package_path_state}" \
      "${post_dumpsys_user0_installed}" "${post_dumpsys_user0_enabled_default}" \
      "${post_logcat_tail_fatal_exception_count}" "${post_logcat_tail_bugreport_reference_count}"
  } > "${PACKAGE_STATE_TSV}"
}

write_status_doc() {
  cat > "${DOC_FILE}" <<EOF_DOC
# ${DOC_TITLE}, 2026-05-17

## Current status

Step ${STEP_ID} executed the approved one-package user 0 test for:

\`\`\`text
${PACKAGE_NAME}
\`\`\`

The test used this exact approved command:

\`\`\`text
adb shell pm uninstall --user 0 ${PACKAGE_NAME}
\`\`\`

The restore command was documented before the package change:

\`\`\`text
adb shell cmd package install-existing --user 0 ${PACKAGE_NAME}
\`\`\`

## Evidence bundle

\`\`\`text
$(basename "${BUNDLE_FILE}")
\`\`\`

## Pre-change result

\`\`\`text
pre_adb_state: ${pre_adb_state}
pre_boot_completed_raw: ${pre_boot_completed_raw}
pre_boot_completed: ${pre_boot_completed}
pre_package_present_for_user0: ${pre_package_present_for_user0}
pre_package_enabled_for_user0: ${pre_package_enabled_for_user0}
pre_package_disabled_for_user0: ${pre_package_disabled_for_user0}
pre_package_path_state: ${pre_package_path_state}
pre_dumpsys_user0_installed: ${pre_dumpsys_user0_installed}
pre_dumpsys_user0_enabled_default: ${pre_dumpsys_user0_enabled_default}
pre_logcat_tail_fatal_exception_count: ${pre_logcat_tail_fatal_exception_count}
pre_logcat_tail_bugreport_reference_count: ${pre_logcat_tail_bugreport_reference_count}
\`\`\`

## Post-change result

\`\`\`text
post_adb_state: ${post_adb_state}
post_boot_completed_raw: ${post_boot_completed_raw}
post_boot_completed: ${post_boot_completed}
post_package_present_for_user0: ${post_package_present_for_user0}
post_package_enabled_for_user0: ${post_package_enabled_for_user0}
post_package_disabled_for_user0: ${post_package_disabled_for_user0}
post_package_path_state: ${post_package_path_state}
post_dumpsys_user0_installed: ${post_dumpsys_user0_installed}
post_dumpsys_user0_enabled_default: ${post_dumpsys_user0_enabled_default}
post_logcat_tail_fatal_exception_count: ${post_logcat_tail_fatal_exception_count}
post_logcat_tail_bugreport_reference_count: ${post_logcat_tail_bugreport_reference_count}
\`\`\`

## Manual post-change checks

\`\`\`text
post_manual_healthy_count: ${post_manual_healthy_count}
post_manual_failure_count: ${post_manual_failure_count}
post_manual_unknown_count: ${post_manual_unknown_count}
\`\`\`

## Restore result

\`\`\`text
restore_executed: ${restore_executed}
restore_reason: ${restore_reason}
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
EOF_DOC
}

write_summary() {
  cat > "${SUMMARY_FILE}" <<EOF_SUMMARY
step=${STEP_ID}
package=${PACKAGE_NAME}
timestamp=${STAMP}
final_result=${final_result}
restore_executed=${restore_executed}
restore_reason=${restore_reason}
pre_package_present_for_user0=${pre_package_present_for_user0}
post_package_present_for_user0=${post_package_present_for_user0}
post_manual_healthy_count=${post_manual_healthy_count}
post_manual_failure_count=${post_manual_failure_count}
post_manual_unknown_count=${post_manual_unknown_count}
post_logcat_tail_fatal_exception_count=${post_logcat_tail_fatal_exception_count}
EOF_SUMMARY
}

update_manifest() {
  local sha size bundle_name tmp
  sha="$(sha256sum "${BUNDLE_FILE}" | awk '{print $1}')"
  size="$(stat -c '%s' "${BUNDLE_FILE}")"
  bundle_name="$(basename "${BUNDLE_FILE}")"
  tmp="$(mktemp)"

  if [[ ! -f "${MANIFEST}" ]]; then
    {
      echo "# Evidence Bundle Manifest"
      echo
      echo "Generated: $(date -Is)"
      echo
      echo "| SHA256 | Size bytes | Bundle |"
      echo "| --- | ---: | --- |"
    } > "${MANIFEST}"
  fi

  grep -v "${bundle_name}" "${MANIFEST}" > "${tmp}" || true
  mv "${tmp}" "${MANIFEST}"
  printf '| `%s` | %s | `%s` |\n' "${sha}" "${size}" "${bundle_name}" >> "${MANIFEST}"
}

main() {
  cd "${REPO_DIR}"

  log "creating Step ${STEP_ID} evidence in ${EVIDENCE_DIR}"

  echo "adb shell cmd package install-existing --user 0 ${PACKAGE_NAME}" > "${RESTORE_COMMANDS_FILE}"
  echo "adb shell pm uninstall --user 0 ${PACKAGE_NAME}" > "${REMOVAL_COMMANDS_FILE}"

  collect_state "pre" "pre"

  if [[ "${pre_adb_state}" != "device" || "${pre_boot_completed}" != "yes" || "${pre_package_present_for_user0}" != "yes" || "${pre_package_enabled_for_user0}" != "yes" ]]; then
    echo "ERROR: pre-change package state is not suitable for Step ${STEP_ID}."
    echo "pre_adb_state: ${pre_adb_state}"
    echo "pre_boot_completed: ${pre_boot_completed}"
    echo "pre_package_present_for_user0: ${pre_package_present_for_user0}"
    echo "pre_package_enabled_for_user0: ${pre_package_enabled_for_user0}"
    echo "pre_package_disabled_for_user0: ${pre_package_disabled_for_user0}"
    echo "pre_package_path_state: ${pre_package_path_state}"
    exit 1
  fi

  echo
  echo "Step ${STEP_ID} exact command set"
  echo
  echo "Target package:"
  echo "  ${PACKAGE_NAME}"
  echo
  echo "Restore command available before removal:"
  echo "  adb shell cmd package install-existing --user 0 ${PACKAGE_NAME}"
  echo
  echo "One package change command:"
  echo "  adb shell pm uninstall --user 0 ${PACKAGE_NAME}"
  echo
  echo "This script will not continue unless you type this exact approval phrase:"
  echo "  ${APPROVAL_PHRASE}"
  echo
  echo "Important manual check wording:"
  echo '  If the phone did not reboot, answer "n" to "unexpected reboot occurred".'
  echo

  read -r -p "Type exact approval phrase now, or press Enter to abort: " approval
  if [[ "${approval}" != "${APPROVAL_PHRASE}" ]]; then
    echo "Step ${STEP_ID} aborted. No package change executed."
    exit 1
  fi

  log "executing approved one-package user 0 uninstall command"
  {
    echo "== approved removal command =="
    echo "adb shell pm uninstall --user 0 ${PACKAGE_NAME}"
    adb shell pm uninstall --user 0 "${PACKAGE_NAME}"
    echo
  } >> "${COMMAND_LOG}" 2>&1

  sleep 2

  collect_state "post" "post"

  manual_checks

  post_manual_healthy_count="$(manual_healthy_count)"
  post_manual_failure_count="$(manual_failure_count)"
  post_manual_unknown_count="$(manual_unknown_count)"

  restore_executed="no"
  restore_reason="not_needed"
  final_result="package_removed_user0_phone_healthy"

  if [[ "${post_adb_state}" != "device" || "${post_boot_completed}" != "yes" || "${post_logcat_tail_fatal_exception_count}" != "0" || "${post_manual_failure_count}" != "0" || "${post_manual_unknown_count}" != "0" ]]; then
    if [[ "${post_package_present_for_user0}" == "no" ]]; then
      restore_executed="yes"
      restore_reason="post_change_health_or_stability_failure"
      log "post-change health or stability failure detected, executing restore command"
      {
        echo "== restore command =="
        echo "adb shell cmd package install-existing --user 0 ${PACKAGE_NAME}"
        adb shell cmd package install-existing --user 0 "${PACKAGE_NAME}"
        echo
      } >> "${COMMAND_LOG}" 2>&1
      final_result="restored_after_post_change_failure"
    else
      restore_executed="no"
      restore_reason="package_still_present_after_failed_test"
      final_result="uninstall_did_not_remove_user0"
    fi
  elif [[ "${post_package_present_for_user0}" != "no" ]]; then
    restore_executed="no"
    restore_reason="package_still_present_after_uninstall_command"
    final_result="uninstall_did_not_remove_user0"
  fi

  write_package_state_tsv
  write_summary
  write_status_doc

  tar -C "${SHARE_DIR}" -czf "${BUNDLE_FILE}" .
  update_manifest

  log "wrote private evidence outside repo: ${EVIDENCE_DIR}"
  log "wrote shareable bundle: ${BUNDLE_FILE}"
  log "wrote status document: ${DOC_FILE}"
  log "updated manifest: ${MANIFEST}"
  log "Step ${STEP_ID} complete: ${final_result}"

  echo
  echo "Step ${STEP_ID} output files:"
  echo "  ${DOC_FILE}"
  echo "  ${BUNDLE_FILE}"
  echo "  ${MANIFEST}"
  echo
  echo "Next local verification command:"
  echo "  cd ${REPO_DIR}"
  echo "  git status --short"
  echo "  sed -n '1,340p' ${DOC_FILE}"
  echo "  grep '$(basename "${BUNDLE_FILE}")' ${MANIFEST} || true"
}

main "$@"
