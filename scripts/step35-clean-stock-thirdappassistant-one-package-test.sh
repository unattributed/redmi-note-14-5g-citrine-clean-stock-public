#!/usr/bin/env bash
set -euo pipefail

REPO="/home/foo/Workspace/android-rom-dev"
STEP="35"
PKG="com.miui.thirdappassistant"
PKG_LABEL="thirdappassistant"
DOC_DATE="2026-05-17"
DOC_DIR="$REPO/docs/13-clean-stock-feasibility"
BUNDLE_DIR="$REPO/evidence/bundles"
MANIFEST="$REPO/evidence/manifests/evidence-bundles.md"
PRIVATE_ROOT="$HOME/android-rom-dev-private-evidence"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_NAME="citrine-clean-stock-${PKG_LABEL}-one-package-test-${STAMP}"
OUT="$PRIVATE_ROOT/$RUN_NAME"
DOC="$DOC_DIR/clean-stock-${PKG_LABEL}-one-package-test-${DOC_DATE}.md"
BUNDLE="$BUNDLE_DIR/${RUN_NAME}-shareable-summary.tar.gz"
APPROVAL_PHRASE="approve step 35 com.miui.thirdappassistant user0 uninstall"
RESTORE_COMMAND="adb shell cmd package install-existing --user 0 ${PKG}"
UNINSTALL_COMMAND="adb shell pm uninstall --user 0 ${PKG}"

mkdir -p "$OUT" "$DOC_DIR" "$BUNDLE_DIR" "$(dirname "$MANIFEST")"

log() {
  printf '[step35] %s\n' "$*"
}

one_line() {
  tr -d '\r' | sed 's/[[:space:]]*$//'
}

normalize_boot() {
  case "$1" in
    1|yes|true|TRUE|Yes|YES) printf 'yes' ;;
    *) printf 'no' ;;
  esac
}

safe_count() {
  local pattern="$1"
  local file="$2"
  if [ -f "$file" ]; then
    grep -Eic "$pattern" "$file" 2>/dev/null || true
  else
    printf '0'
  fi
}

write_kv() {
  local key="$1"
  local value="$2"
  printf '%s=%s\n' "$key" "$value" >> "$OUT/state.env"
}

capture_state() {
  local prefix="$1"

  local adb_state boot_raw boot_norm
  adb_state="$(adb get-state 2>/dev/null | one_line || true)"
  boot_raw="$(adb shell getprop sys.boot_completed 2>/dev/null | one_line || true)"
  boot_norm="$(normalize_boot "$boot_raw")"

  adb shell pm list packages --user 0 > "$OUT/${prefix}-pm-list-packages-user0.txt" 2>&1 || true
  adb shell pm list packages -e --user 0 > "$OUT/${prefix}-pm-list-packages-enabled-user0.txt" 2>&1 || true
  adb shell pm list packages -d --user 0 > "$OUT/${prefix}-pm-list-packages-disabled-user0.txt" 2>&1 || true
  adb shell pm path "$PKG" > "$OUT/${prefix}-pm-path.txt" 2>&1 || true
  adb shell dumpsys package "$PKG" > "$OUT/${prefix}-dumpsys-package.txt" 2>&1 || true
  adb logcat -d -t 300 > "$OUT/${prefix}-logcat-tail.txt" 2>&1 || true

  local present enabled disabled path_state dumpsys_installed dumpsys_enabled fatal_count package_ref_count

  if grep -Fxq "package:${PKG}" "$OUT/${prefix}-pm-list-packages-user0.txt"; then
    present="yes"
  else
    present="no"
  fi

  if grep -Fxq "package:${PKG}" "$OUT/${prefix}-pm-list-packages-enabled-user0.txt"; then
    enabled="yes"
  else
    enabled="no"
  fi

  if grep -Fxq "package:${PKG}" "$OUT/${prefix}-pm-list-packages-disabled-user0.txt"; then
    disabled="yes"
  else
    disabled="no"
  fi

  if grep -q '^package:' "$OUT/${prefix}-pm-path.txt"; then
    path_state="present"
  else
    path_state="unknown"
  fi

  if grep -Eq 'User 0:.*installed=true' "$OUT/${prefix}-dumpsys-package.txt"; then
    dumpsys_installed="yes"
  else
    dumpsys_installed="no"
  fi

  if grep -Eq 'User 0:.*enabled=0' "$OUT/${prefix}-dumpsys-package.txt"; then
    dumpsys_enabled="yes"
  else
    dumpsys_enabled="no"
  fi

  fatal_count="$(safe_count 'FATAL EXCEPTION' "$OUT/${prefix}-logcat-tail.txt")"
  package_ref_count="$(safe_count 'com\.miui\.thirdappassistant|thirdappassistant|thirdapp' "$OUT/${prefix}-logcat-tail.txt")"

  write_kv "${prefix}_adb_state" "$adb_state"
  write_kv "${prefix}_boot_completed_raw" "$boot_raw"
  write_kv "${prefix}_boot_completed" "$boot_norm"
  write_kv "${prefix}_package_present_for_user0" "$present"
  write_kv "${prefix}_package_enabled_for_user0" "$enabled"
  write_kv "${prefix}_package_disabled_for_user0" "$disabled"
  write_kv "${prefix}_package_path_state" "$path_state"
  write_kv "${prefix}_dumpsys_user0_installed" "$dumpsys_installed"
  write_kv "${prefix}_dumpsys_user0_enabled_default" "$dumpsys_enabled"
  write_kv "${prefix}_logcat_tail_fatal_exception_count" "$fatal_count"
  write_kv "${prefix}_logcat_tail_thirdappassistant_reference_count" "$package_ref_count"
}

get_state_value() {
  local key="$1"
  grep -E "^${key}=" "$OUT/state.env" | tail -n 1 | cut -d= -f2-
}

ask_check() {
  local key="$1"
  local prompt="$2"
  local answer note
  while true; do
    echo
    echo "[post-change phone check] $prompt"
    read -r -p "Answer y, n, or u for unknown: " answer
    case "$answer" in
      y|Y|n|N|u|U)
        answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
        break
        ;;
      *)
        echo "Please answer y, n, or u."
        ;;
    esac
  done

  read -r -p "Optional note, press Enter to skip: " note
  printf '%s=%s\n' "$key" "$answer" >> "$OUT/manual-checks.env"
  printf '%s_note=%s\n' "$key" "$note" >> "$OUT/manual-checks.env"
}

write_status_doc() {
  local final_result="$1"
  local restore_executed="$2"
  local restore_reason="$3"

  cat > "$DOC" <<EOF
# Clean Stock Third App Assistant One-Package Test, ${DOC_DATE}

## Current status

Step ${STEP} executed the approved one-package user 0 test for:

\`\`\`text
${PKG}
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
$(basename "$BUNDLE")
\`\`\`

## Pre-change result

\`\`\`text
pre_adb_state: $(get_state_value pre_adb_state)
pre_boot_completed_raw: $(get_state_value pre_boot_completed_raw)
pre_boot_completed: $(get_state_value pre_boot_completed)
pre_package_present_for_user0: $(get_state_value pre_package_present_for_user0)
pre_package_enabled_for_user0: $(get_state_value pre_package_enabled_for_user0)
pre_package_disabled_for_user0: $(get_state_value pre_package_disabled_for_user0)
pre_package_path_state: $(get_state_value pre_package_path_state)
pre_dumpsys_user0_installed: $(get_state_value pre_dumpsys_user0_installed)
pre_dumpsys_user0_enabled_default: $(get_state_value pre_dumpsys_user0_enabled_default)
pre_logcat_tail_fatal_exception_count: $(get_state_value pre_logcat_tail_fatal_exception_count)
pre_logcat_tail_thirdappassistant_reference_count: $(get_state_value pre_logcat_tail_thirdappassistant_reference_count)
\`\`\`

## Post-change result

\`\`\`text
post_adb_state: $(get_state_value post_adb_state)
post_boot_completed_raw: $(get_state_value post_boot_completed_raw)
post_boot_completed: $(get_state_value post_boot_completed)
post_package_present_for_user0: $(get_state_value post_package_present_for_user0)
post_package_enabled_for_user0: $(get_state_value post_package_enabled_for_user0)
post_package_disabled_for_user0: $(get_state_value post_package_disabled_for_user0)
post_package_path_state: $(get_state_value post_package_path_state)
post_dumpsys_user0_installed: $(get_state_value post_dumpsys_user0_installed)
post_dumpsys_user0_enabled_default: $(get_state_value post_dumpsys_user0_enabled_default)
post_logcat_tail_fatal_exception_count: $(get_state_value post_logcat_tail_fatal_exception_count)
post_logcat_tail_thirdappassistant_reference_count: $(get_state_value post_logcat_tail_thirdappassistant_reference_count)
\`\`\`

## Manual post-change checks

\`\`\`text
post_manual_healthy_count: $(get_state_value post_manual_healthy_count)
post_manual_failure_count: $(get_state_value post_manual_failure_count)
post_manual_unknown_count: $(get_state_value post_manual_unknown_count)
\`\`\`

## Restore result

\`\`\`text
restore_executed: ${restore_executed}
restore_reason: ${restore_reason}
EOF

  if [ "$restore_executed" = "yes" ]; then
    cat >> "$DOC" <<EOF
restore_adb_state: $(get_state_value restore_adb_state)
restore_boot_completed_raw: $(get_state_value restore_boot_completed_raw)
restore_boot_completed: $(get_state_value restore_boot_completed)
restore_package_present_for_user0: $(get_state_value restore_package_present_for_user0)
restore_package_enabled_for_user0: $(get_state_value restore_package_enabled_for_user0)
restore_package_disabled_for_user0: $(get_state_value restore_package_disabled_for_user0)
restore_package_path_state: $(get_state_value restore_package_path_state)
restore_dumpsys_user0_installed: $(get_state_value restore_dumpsys_user0_installed)
restore_dumpsys_user0_enabled_default: $(get_state_value restore_dumpsys_user0_enabled_default)
restore_logcat_tail_fatal_exception_count: $(get_state_value restore_logcat_tail_fatal_exception_count)
restore_logcat_tail_thirdappassistant_reference_count: $(get_state_value restore_logcat_tail_thirdappassistant_reference_count)
EOF
  fi

  cat >> "$DOC" <<EOF
\`\`\`

## Important package-state interpretation

After \`pm uninstall --user 0\`, \`pm path ${PKG}\` may be unavailable for the current user context. This is not treated as failure when the package is absent for Android user 0, the phone remains booted, the manual checks pass, and the restore command was already documented before removal.

## Safety boundary

No bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, relock, package disable, package data clearing, app force-stop, or settings mutation was approved or performed.

## Current conclusion

\`\`\`text
final_result: ${final_result}
\`\`\`

If the final result is \`package_removed_user0_phone_healthy\`, then \`${PKG}\` was removed only for Android user 0 and the phone remained healthy after the package change.
EOF
}

create_bundle_and_manifest() {
  local summary_dir="$OUT/shareable-summary"
  mkdir -p "$summary_dir"

  cp "$DOC" "$summary_dir/"
  cp "$OUT/state.env" "$summary_dir/state.env"
  cp "$OUT/manual-checks.env" "$summary_dir/manual-checks.env"
  cp "$OUT/uninstall-command-output.txt" "$summary_dir/uninstall-command-output.txt" 2>/dev/null || true
  cp "$OUT/restore-command-output.txt" "$summary_dir/restore-command-output.txt" 2>/dev/null || true
  cp "$OUT/pre-pm-list-packages-user0.txt" "$summary_dir/pre-pm-list-packages-user0.txt"
  cp "$OUT/pre-pm-list-packages-enabled-user0.txt" "$summary_dir/pre-pm-list-packages-enabled-user0.txt"
  cp "$OUT/post-pm-list-packages-user0.txt" "$summary_dir/post-pm-list-packages-user0.txt"
  cp "$OUT/post-pm-list-packages-enabled-user0.txt" "$summary_dir/post-pm-list-packages-enabled-user0.txt"
  cp "$OUT/post-pm-path.txt" "$summary_dir/post-pm-path.txt"

  tar -C "$summary_dir" -czf "$BUNDLE" .

  local sha size bundle_name
  sha="$(sha256sum "$BUNDLE" | awk '{print $1}')"
  size="$(stat -c '%s' "$BUNDLE")"
  bundle_name="$(basename "$BUNDLE")"

  if [ ! -f "$MANIFEST" ]; then
    cat > "$MANIFEST" <<MANIFEST_EOF
# Evidence Bundle Manifest

Generated: $(date -Is)

| SHA256 | Size bytes | Bundle |
| --- | ---: | --- |
MANIFEST_EOF
  fi

  if ! grep -Fq "$bundle_name" "$MANIFEST"; then
    printf '| `%s` | %s | `%s` |\n' "$sha" "$size" "$bundle_name" >> "$MANIFEST"
  fi
}

main() {
  log "creating Step ${STEP} evidence in $OUT"

  : > "$OUT/state.env"
  : > "$OUT/manual-checks.env"

  if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: adb is not available in PATH." >&2
    exit 1
  fi

  capture_state pre

  if [ "$(get_state_value pre_adb_state)" != "device" ] ||
     [ "$(get_state_value pre_boot_completed)" != "yes" ] ||
     [ "$(get_state_value pre_package_present_for_user0)" != "yes" ] ||
     [ "$(get_state_value pre_package_enabled_for_user0)" != "yes" ] ||
     [ "$(get_state_value pre_package_disabled_for_user0)" != "no" ]; then
    echo "ERROR: pre-change package state is not suitable for Step ${STEP}."
    echo "pre_adb_state: $(get_state_value pre_adb_state)"
    echo "pre_boot_completed: $(get_state_value pre_boot_completed)"
    echo "pre_package_present_for_user0: $(get_state_value pre_package_present_for_user0)"
    echo "pre_package_enabled_for_user0: $(get_state_value pre_package_enabled_for_user0)"
    echo "pre_package_disabled_for_user0: $(get_state_value pre_package_disabled_for_user0)"
    echo "pre_package_path_state: $(get_state_value pre_package_path_state)"
    exit 1
  fi

  cat <<EOF

Step ${STEP} exact command set

Target package:
  ${PKG}

Restore command available before removal:
  ${RESTORE_COMMAND}

One package change command:
  ${UNINSTALL_COMMAND}

This script will not continue unless you type this exact approval phrase:
  ${APPROVAL_PHRASE}

Important manual check wording:
  If the phone did not reboot, answer "n" to "unexpected reboot occurred".

EOF

  local approval
  read -r -p "Type exact approval phrase now, or press Enter to abort: " approval
  if [ "$approval" != "$APPROVAL_PHRASE" ]; then
    echo "ERROR: approval phrase did not match. No package change executed."
    exit 1
  fi

  log "executing approved one-package user 0 uninstall command"
  printf '%s\n' "$UNINSTALL_COMMAND" > "$OUT/uninstall-command.txt"

  set +e
  adb shell pm uninstall --user 0 "$PKG" > "$OUT/uninstall-command-output.txt" 2>&1
  local uninstall_rc=$?
  set -e
  write_kv "uninstall_exit_code" "$uninstall_rc"
  write_kv "uninstall_output" "$(tr '\n' ' ' < "$OUT/uninstall-command-output.txt" | sed 's/[[:space:]]*$//')"

  capture_state post

  cat <<EOF

Now check the phone in its current state. The phone is not expected to reboot.
Answer the following checks based on what you can verify now.

For the first question:
  answer n if the phone did not reboot
  answer y only if an unexpected reboot occurred

EOF

  ask_check unexpected_reboot "unexpected reboot occurred"
  ask_check lock_screen_unlocks "lock screen unlocks normally, or remains unlockable if already unlocked"
  ask_check touchscreen_works "touchscreen works"
  ask_check launcher_opens "launcher opens"
  ask_check settings_opens "settings opens"
  ask_check phone_app_opens "phone app opens"
  ask_check sms_app_opens "SMS app opens"
  ask_check wifi_works_or_unchanged "Wi-Fi works or state is unchanged"
  ask_check mobile_data_works_or_unchanged "mobile data works or state is unchanged"
  ask_check camera_opens "camera opens"
  ask_check play_store_opens "Play Store opens"
  ask_check chrome_or_webview_browsing_works "Chrome or WebView-backed browsing works"
  ask_check notifications_not_obviously_broken "notifications are not obviously broken"
  ask_check no_repeated_crash_dialogs "no repeated crash dialogs are visible"

  local healthy_count=0
  local failure_count=0
  local unknown_count=0

  while IFS='=' read -r key value; do
    case "$key" in
      *_note) continue ;;
    esac

    if [ "$key" = "unexpected_reboot" ]; then
      case "$value" in
        n) healthy_count=$((healthy_count + 1)) ;;
        y) failure_count=$((failure_count + 1)) ;;
        u) unknown_count=$((unknown_count + 1)) ;;
      esac
    else
      case "$value" in
        y) healthy_count=$((healthy_count + 1)) ;;
        n) failure_count=$((failure_count + 1)) ;;
        u) unknown_count=$((unknown_count + 1)) ;;
      esac
    fi
  done < "$OUT/manual-checks.env"

  write_kv "post_manual_healthy_count" "$healthy_count"
  write_kv "post_manual_failure_count" "$failure_count"
  write_kv "post_manual_unknown_count" "$unknown_count"

  local final_result restore_executed restore_reason should_restore
  final_result="undetermined"
  restore_executed="no"
  restore_reason="not_needed"
  should_restore="no"

  if [ "$uninstall_rc" -ne 0 ]; then
    final_result="uninstall_command_failed"
    restore_reason="uninstall_command_failed"
    should_restore="no"
  elif [ "$(get_state_value post_adb_state)" != "device" ]; then
    final_result="post_change_adb_not_device"
    restore_reason="post_change_adb_not_device"
    should_restore="yes"
  elif [ "$(get_state_value post_boot_completed)" != "yes" ]; then
    final_result="post_change_boot_not_completed"
    restore_reason="post_change_boot_not_completed"
    should_restore="yes"
  elif [ "$(get_state_value post_logcat_tail_fatal_exception_count)" != "0" ]; then
    final_result="post_change_fatal_exception_detected"
    restore_reason="post_change_fatal_exception_detected"
    should_restore="yes"
  elif [ "$failure_count" -gt 0 ]; then
    final_result="post_change_manual_failure"
    restore_reason="post_change_manual_failure"
    should_restore="yes"
  elif [ "$unknown_count" -gt 0 ]; then
    final_result="post_change_manual_unknown"
    restore_reason="post_change_manual_unknown"
    should_restore="yes"
  elif [ "$(get_state_value post_package_present_for_user0)" = "no" ]; then
    final_result="package_removed_user0_phone_healthy"
    restore_reason="not_needed"
    should_restore="no"
  else
    final_result="package_still_present_after_uninstall"
    restore_reason="not_needed"
    should_restore="no"
  fi

  if [ "$should_restore" = "yes" ]; then
    log "post-change failure detected, executing restore command"
    restore_executed="yes"
    printf '%s\n' "$RESTORE_COMMAND" > "$OUT/restore-command.txt"
    adb shell cmd package install-existing --user 0 "$PKG" > "$OUT/restore-command-output.txt" 2>&1 || true
    capture_state restore
  fi

  write_status_doc "$final_result" "$restore_executed" "$restore_reason"
  create_bundle_and_manifest

  log "wrote private evidence outside repo: $OUT"
  log "wrote shareable bundle: $BUNDLE"
  log "wrote status document: $DOC"
  log "updated manifest: $MANIFEST"
  log "Step ${STEP} complete: $final_result"

  cat <<EOF

Step ${STEP} output files:
  ${DOC}
  ${BUNDLE}
  ${MANIFEST}

Next local verification command:
  cd ${REPO}
  git status --short
  sed -n '1,340p' ${DOC}
  grep '$(basename "$BUNDLE")' ${MANIFEST} || true
EOF
}

main "$@"
