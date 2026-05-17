#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/home/foo/Workspace/android-rom-dev"
STEP_ID="36"
STEP_SLUG="clean-stock-first-batch-postchange-baseline"
DOC_DIR="$ROOT_DIR/docs/13-clean-stock-feasibility"
SCRIPT_DIR="$ROOT_DIR/scripts"
BUNDLE_DIR="$ROOT_DIR/evidence/bundles"
MANIFEST="$ROOT_DIR/evidence/manifests/evidence-bundles.md"
PRIVATE_BASE="$HOME/android-rom-dev-private-evidence"
STAMP="$(date +%Y%m%d-%H%M%S)"
EVIDENCE_DIR="$PRIVATE_BASE/citrine-$STEP_SLUG-$STAMP"
SHAREABLE_NAME="citrine-$STEP_SLUG-$STAMP-shareable-summary.tar.gz"
SHAREABLE_PATH="$BUNDLE_DIR/$SHAREABLE_NAME"
STATUS_DOC="$DOC_DIR/$STEP_SLUG-2026-05-17.md"
SUMMARY_FILE="$EVIDENCE_DIR/summary.txt"
PACKAGE_TSV="$EVIDENCE_DIR/package-state.tsv"
MANUAL_TSV="$EVIDENCE_DIR/manual-checks.tsv"
RAW_DIR="$EVIDENCE_DIR/raw"

TARGET_PACKAGES=(
  "com.miui.analytics"
  "com.miui.msa.global"
  "com.miui.thirdappassistant"
)

MANUAL_CHECKS=(
  "unexpected reboot occurred"
  "lock screen unlocks normally, or remains unlockable if already unlocked"
  "touchscreen works"
  "launcher opens"
  "settings opens"
  "phone app opens"
  "SMS app opens"
  "Wi-Fi works or state is unchanged"
  "mobile data works or state is unchanged"
  "camera opens"
  "Play Store opens"
  "Chrome or WebView-backed browsing works"
  "notifications are not obviously broken"
  "no repeated crash dialogs are visible"
)

mkdir -p "$DOC_DIR" "$SCRIPT_DIR" "$BUNDLE_DIR" "$(dirname "$MANIFEST")" "$RAW_DIR" "$EVIDENCE_DIR/shareable"

log() {
  printf '[step36] %s\n' "$*"
}

adb_shell() {
  adb shell "$@" 2>/dev/null | tr -d '\r' || true
}

normalize_boot_completed() {
  local raw="$1"
  case "$raw" in
    1|yes|true) printf 'yes' ;;
    0|no|false|'') printf 'no' ;;
    *) printf '%s' "$raw" ;;
  esac
}

count_logcat_pattern() {
  local pattern="$1"
  adb logcat -d -t 5000 2>/dev/null | tr -d '\r' | grep -ciE "$pattern" || true
}

package_present_for_user0() {
  local package="$1"
  if adb_shell pm list packages --user 0 | grep -Fxq "package:$package"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

package_enabled_for_user0() {
  local package="$1"
  if adb_shell pm list packages -e --user 0 | grep -Fxq "package:$package"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

package_disabled_for_user0() {
  local package="$1"
  if adb_shell pm list packages -d --user 0 | grep -Fxq "package:$package"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

package_path_state() {
  local package="$1"
  if adb_shell pm path "$package" | grep -q '^package:'; then
    printf 'present'
  else
    printf 'unknown'
  fi
}

collect_raw_package_state() {
  local package="$1"
  local safe_name
  safe_name="${package//./_}"

  adb_shell pm list packages --user 0 > "$RAW_DIR/${safe_name}-pm-list-user0.txt"
  adb_shell pm list packages -e --user 0 > "$RAW_DIR/${safe_name}-pm-list-enabled-user0.txt"
  adb_shell pm list packages -d --user 0 > "$RAW_DIR/${safe_name}-pm-list-disabled-user0.txt"
  adb_shell pm path "$package" > "$RAW_DIR/${safe_name}-pm-path.txt"
  adb shell dumpsys package "$package" > "$RAW_DIR/${safe_name}-dumpsys-package.txt" 2>&1 || true
}

ask_check() {
  local key="$1"
  local prompt="$2"
  local answer=""
  local note=""

  while true; do
    printf '\n[post-batch phone check] %s\n' "$prompt"
    read -r -p 'Answer y, n, or u for unknown: ' answer
    case "$answer" in
      y|Y|n|N|u|U)
        answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
        break
        ;;
      *)
        printf 'Invalid answer. Use y, n, or u.\n'
        ;;
    esac
  done

  read -r -p 'Optional note, press Enter to skip: ' note || true
  printf '%s\t%s\t%s\t%s\n' "$key" "$answer" "$prompt" "$note" >> "$MANUAL_TSV"
}

ensure_repo() {
  if [[ ! -d "$ROOT_DIR/.git" ]]; then
    printf 'ERROR: expected git repository at %s\n' "$ROOT_DIR" >&2
    exit 1
  fi
}

main() {
  ensure_repo

  log "creating Step 36 evidence in $EVIDENCE_DIR"

  local adb_state
  local boot_raw
  local boot_normalized
  local fatal_count
  local absent_count=0
  local present_count=0
  local package
  local present
  local enabled
  local disabled
  local path_state
  local healthy_count=0
  local failure_count=0
  local unknown_count=0
  local final_result="first_batch_needs_review"

  adb_state="$(adb get-state 2>/dev/null | tr -d '\r' || true)"
  boot_raw="$(adb_shell getprop sys.boot_completed)"
  boot_normalized="$(normalize_boot_completed "$boot_raw")"
  fatal_count="$(count_logcat_pattern 'FATAL EXCEPTION')"

  if [[ "$adb_state" != "device" ]]; then
    printf 'ERROR: adb state is not device: %s\n' "$adb_state" >&2
    exit 1
  fi

  if [[ "$boot_normalized" != "yes" ]]; then
    printf 'ERROR: boot_completed is not yes. raw=%s normalized=%s\n' "$boot_raw" "$boot_normalized" >&2
    exit 1
  fi

  printf 'package\tpresent_user0\tenabled_user0\tdisabled_user0\tpath_state\trestore_command\n' > "$PACKAGE_TSV"

  for package in "${TARGET_PACKAGES[@]}"; do
    collect_raw_package_state "$package"
    present="$(package_present_for_user0 "$package")"
    enabled="$(package_enabled_for_user0 "$package")"
    disabled="$(package_disabled_for_user0 "$package")"
    path_state="$(package_path_state "$package")"

    if [[ "$present" == "no" ]]; then
      absent_count=$((absent_count + 1))
    else
      present_count=$((present_count + 1))
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$package" \
      "$present" \
      "$enabled" \
      "$disabled" \
      "$path_state" \
      "adb shell cmd package install-existing --user 0 $package" >> "$PACKAGE_TSV"
  done

  cat > "$MANUAL_TSV" <<'MANUALEOF'
key	answer	prompt	note
MANUALEOF

  cat <<'PROMPT'

Step 36 first-batch post-change phone baseline

The phone is not expected to reboot.
For the first question:
  answer n if the phone did not reboot
  answer y only if an unexpected reboot occurred

PROMPT

  ask_check unexpected_reboot "unexpected reboot occurred"
  ask_check lock_screen "lock screen unlocks normally, or remains unlockable if already unlocked"
  ask_check touchscreen "touchscreen works"
  ask_check launcher "launcher opens"
  ask_check settings "settings opens"
  ask_check phone_app "phone app opens"
  ask_check sms_app "SMS app opens"
  ask_check wifi "Wi-Fi works or state is unchanged"
  ask_check mobile_data "mobile data works or state is unchanged"
  ask_check camera "camera opens"
  ask_check play_store "Play Store opens"
  ask_check browser "Chrome or WebView-backed browsing works"
  ask_check notifications "notifications are not obviously broken"
  ask_check crash_dialogs "no repeated crash dialogs are visible"

  while IFS=$'\t' read -r key answer prompt note; do
    [[ "$key" == "key" ]] && continue
    if [[ "$key" == "unexpected_reboot" ]]; then
      case "$answer" in
        n) healthy_count=$((healthy_count + 1)) ;;
        y) failure_count=$((failure_count + 1)) ;;
        u) unknown_count=$((unknown_count + 1)) ;;
      esac
    else
      case "$answer" in
        y) healthy_count=$((healthy_count + 1)) ;;
        n) failure_count=$((failure_count + 1)) ;;
        u) unknown_count=$((unknown_count + 1)) ;;
      esac
    fi
  done < "$MANUAL_TSV"

  if [[ "$absent_count" -eq 3 && "$present_count" -eq 0 && "$adb_state" == "device" && "$boot_normalized" == "yes" && "$failure_count" -eq 0 && "$unknown_count" -eq 0 ]]; then
    final_result="first_batch_removed_user0_phone_healthy"
  fi

  cat > "$SUMMARY_FILE" <<EOF_SUMMARY
step: 36
step_name: clean stock first-batch post-change baseline
timestamp: $STAMP
adb_state: $adb_state
boot_completed_raw: $boot_raw
boot_completed: $boot_normalized
fatal_exception_count_tail_5000: $fatal_count
target_package_count: ${#TARGET_PACKAGES[@]}
removed_for_user0_count: $absent_count
present_for_user0_count: $present_count
manual_healthy_count: $healthy_count
manual_failure_count: $failure_count
manual_unknown_count: $unknown_count
final_result: $final_result
safety_boundary: read-only validation only, no uninstall, no restore, no disable, no package data clearing, no flashing, no bootloader action, no userdata erase
EOF_SUMMARY

  cp "$SUMMARY_FILE" "$EVIDENCE_DIR/shareable/summary.txt"
  cp "$PACKAGE_TSV" "$EVIDENCE_DIR/shareable/package-state.tsv"
  cp "$MANUAL_TSV" "$EVIDENCE_DIR/shareable/manual-checks.tsv"

  cat > "$STATUS_DOC" <<EOF_DOC
# Clean Stock First Batch Post-Change Baseline, 2026-05-17

## Current status

Step 36 collected a read-only post-change baseline after the first clean-stock package batch.

The first batch packages are:

\`\`\`text
com.miui.analytics
com.miui.msa.global
com.miui.thirdappassistant
\`\`\`

Step 36 did not execute uninstall, restore, disable, package data clearing, force-stop, settings mutation, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

## Evidence bundle

\`\`\`text
$SHAREABLE_NAME
\`\`\`

## Device state

\`\`\`text
adb_state: $adb_state
boot_completed_raw: $boot_raw
boot_completed: $boot_normalized
fatal_exception_count_tail_5000: $fatal_count
\`\`\`

## First batch package state

\`\`\`text
$(column -t -s $'\t' "$PACKAGE_TSV")
\`\`\`

## Manual post-batch checks

\`\`\`text
manual_healthy_count: $healthy_count
manual_failure_count: $failure_count
manual_unknown_count: $unknown_count
\`\`\`

## Restore commands remain available

\`\`\`text
adb shell cmd package install-existing --user 0 com.miui.analytics
adb shell cmd package install-existing --user 0 com.miui.msa.global
adb shell cmd package install-existing --user 0 com.miui.thirdappassistant
\`\`\`

## Safety boundary

This step is validation only. It records the state after the first batch, but does not approve a second cleanup batch by itself.

## Current conclusion

\`\`\`text
final_result: $final_result
\`\`\`

If the final result is \`first_batch_removed_user0_phone_healthy\`, then all three first-batch packages are absent for Android user 0 and the phone remains healthy in observed use.
EOF_DOC

  tar -C "$EVIDENCE_DIR/shareable" -czf "$SHAREABLE_PATH" .

  local sha
  local size
  sha="$(sha256sum "$SHAREABLE_PATH" | awk '{print $1}')"
  size="$(stat -c '%s' "$SHAREABLE_PATH")"

  if [[ ! -f "$MANIFEST" ]]; then
    cat > "$MANIFEST" <<'EOF_MANIFEST'
# Evidence Bundle Manifest

| SHA256 | Size bytes | Bundle |
| --- | ---: | --- |
EOF_MANIFEST
  fi

  local tmp_manifest
  tmp_manifest="$(mktemp)"
  grep -Fv "$SHAREABLE_NAME" "$MANIFEST" > "$tmp_manifest" || true
  printf '| `%s` | %s | `%s` |\n' "$sha" "$size" "$SHAREABLE_NAME" >> "$tmp_manifest"
  mv "$tmp_manifest" "$MANIFEST"

  log "wrote private evidence outside repo: $EVIDENCE_DIR"
  log "wrote shareable bundle: $SHAREABLE_PATH"
  log "wrote status document: $STATUS_DOC"
  log "updated manifest: $MANIFEST"
  log "Step 36 complete: $final_result"

  cat <<EOF_NEXT

Step 36 output files:
  $STATUS_DOC
  $SHAREABLE_PATH
  $MANIFEST

Next local verification command:
  cd $ROOT_DIR
  git status --short
  sed -n '1,300p' $STATUS_DOC
  grep '$SHAREABLE_NAME' $MANIFEST || true
EOF_NEXT
}

main "$@"
