#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/home/foo/Workspace/android-rom-dev"
STEP_ID="37"
STEP_SLUG="clean-stock-second-batch-command-plan"
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
FIRST_BATCH_TSV="$EVIDENCE_DIR/first-batch-state.tsv"
CANDIDATE_TSV="$EVIDENCE_DIR/remaining-review-candidates.tsv"
COMMAND_TSV="$EVIDENCE_DIR/second-batch-command-plan.tsv"
DEFERRED_TSV="$EVIDENCE_DIR/deferred-review-candidates.tsv"
RAW_DIR="$EVIDENCE_DIR/raw"

FIRST_BATCH_REMOVED=(
  "com.miui.analytics"
  "com.miui.msa.global"
  "com.miui.thirdappassistant"
)

REMAINING_REVIEW_CANDIDATES=(
  "com.miui.bugreport"
  "com.miui.miwallpaper"
  "com.miui.miwallpaper.config.overlay"
  "com.miui.miwallpaper.overlay"
  "com.miui.miwallpaper.overlay.customize"
  "com.miui.videoplayer"
  "com.miui.wallpaper.overlay"
  "com.miui.wallpaper.overlay.customize"
  "com.miui.yellowpage"
  "com.xiaomi.discover"
  "com.xiaomi.mipicks"
)

SECOND_BATCH_ORDER=(
  "com.miui.bugreport"
  "com.xiaomi.mipicks"
  "com.xiaomi.discover"
  "com.miui.videoplayer"
  "com.miui.yellowpage"
)

DEFERRED_REVIEW=(
  "com.miui.miwallpaper"
  "com.miui.miwallpaper.config.overlay"
  "com.miui.miwallpaper.overlay"
  "com.miui.miwallpaper.overlay.customize"
  "com.miui.wallpaper.overlay"
  "com.miui.wallpaper.overlay.customize"
)

mkdir -p "$DOC_DIR" "$SCRIPT_DIR" "$BUNDLE_DIR" "$(dirname "$MANIFEST")" "$RAW_DIR" "$EVIDENCE_DIR/shareable"

log() {
  printf '[step37] %s\n' "$*"
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

ensure_repo() {
  if [[ ! -d "$ROOT_DIR/.git" ]]; then
    printf 'ERROR: expected git repository at %s\n' "$ROOT_DIR" >&2
    exit 1
  fi
}

write_manifest_entry() {
  local sha
  local size
  local tmp_manifest

  sha="$(sha256sum "$SHAREABLE_PATH" | awk '{print $1}')"
  size="$(stat -c '%s' "$SHAREABLE_PATH")"

  if [[ ! -f "$MANIFEST" ]]; then
    cat > "$MANIFEST" <<'EOF_MANIFEST'
# Evidence Bundle Manifest

| SHA256 | Size bytes | Bundle |
| --- | ---: | --- |
EOF_MANIFEST
  fi

  tmp_manifest="$(mktemp)"
  grep -Fv "$SHAREABLE_NAME" "$MANIFEST" > "$tmp_manifest" || true
  printf '| `%s` | %s | `%s` |\n' "$sha" "$size" "$SHAREABLE_NAME" >> "$tmp_manifest"
  mv "$tmp_manifest" "$MANIFEST"
}

main() {
  ensure_repo

  log "creating Step 37 evidence in $EVIDENCE_DIR"

  local adb_state
  local boot_raw
  local boot_normalized
  local fatal_count
  local package
  local present
  local enabled
  local disabled
  local path_state
  local first_batch_absent_count=0
  local first_batch_present_count=0
  local second_batch_ready_count=0
  local second_batch_not_ready_count=0
  local remaining_present_count=0
  local final_result="second_batch_plan_needs_review"

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

  printf 'package\tpresent_user0\tenabled_user0\tdisabled_user0\tpath_state\trestore_command\n' > "$FIRST_BATCH_TSV"
  for package in "${FIRST_BATCH_REMOVED[@]}"; do
    collect_raw_package_state "$package"
    present="$(package_present_for_user0 "$package")"
    enabled="$(package_enabled_for_user0 "$package")"
    disabled="$(package_disabled_for_user0 "$package")"
    path_state="$(package_path_state "$package")"

    if [[ "$present" == "no" ]]; then
      first_batch_absent_count=$((first_batch_absent_count + 1))
    else
      first_batch_present_count=$((first_batch_present_count + 1))
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$package" "$present" "$enabled" "$disabled" "$path_state" \
      "adb shell cmd package install-existing --user 0 $package" >> "$FIRST_BATCH_TSV"
  done

  printf 'package\tpresent_user0\tenabled_user0\tdisabled_user0\tpath_state\trestore_command\tfuture_removal_command_not_approved\n' > "$CANDIDATE_TSV"
  for package in "${REMAINING_REVIEW_CANDIDATES[@]}"; do
    collect_raw_package_state "$package"
    present="$(package_present_for_user0 "$package")"
    enabled="$(package_enabled_for_user0 "$package")"
    disabled="$(package_disabled_for_user0 "$package")"
    path_state="$(package_path_state "$package")"

    if [[ "$present" == "yes" ]]; then
      remaining_present_count=$((remaining_present_count + 1))
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$package" "$present" "$enabled" "$disabled" "$path_state" \
      "adb shell cmd package install-existing --user 0 $package" \
      "adb shell pm uninstall --user 0 $package" >> "$CANDIDATE_TSV"
  done

  printf 'order\tpackage\tpresent_user0\tenabled_user0\tdisabled_user0\tpath_state\trestore_command\tfuture_removal_command_not_approved\n' > "$COMMAND_TSV"
  local order=1
  for package in "${SECOND_BATCH_ORDER[@]}"; do
    present="$(package_present_for_user0 "$package")"
    enabled="$(package_enabled_for_user0 "$package")"
    disabled="$(package_disabled_for_user0 "$package")"
    path_state="$(package_path_state "$package")"

    if [[ "$present" == "yes" && "$enabled" == "yes" ]]; then
      second_batch_ready_count=$((second_batch_ready_count + 1))
    else
      second_batch_not_ready_count=$((second_batch_not_ready_count + 1))
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$order" "$package" "$present" "$enabled" "$disabled" "$path_state" \
      "adb shell cmd package install-existing --user 0 $package" \
      "adb shell pm uninstall --user 0 $package" >> "$COMMAND_TSV"
    order=$((order + 1))
  done

  printf 'package\treason\n' > "$DEFERRED_TSV"
  for package in "${DEFERRED_REVIEW[@]}"; do
    printf '%s\t%s\n' "$package" "deferred because wallpaper and overlay packages can affect user interface appearance and should be handled after non-UI review-only candidates" >> "$DEFERRED_TSV"
  done

  if [[ "$first_batch_absent_count" -eq 3 && "$first_batch_present_count" -eq 0 && "$second_batch_ready_count" -ge 1 && "$adb_state" == "device" && "$boot_normalized" == "yes" ]]; then
    final_result="second_batch_restore_first_plan_ready"
  fi

  cat > "$SUMMARY_FILE" <<EOF_SUMMARY
step: 37
step_name: clean stock second-batch restore-first command plan
timestamp: $STAMP
adb_state: $adb_state
boot_completed_raw: $boot_raw
boot_completed: $boot_normalized
fatal_exception_count_tail_5000: $fatal_count
first_batch_absent_user0_count: $first_batch_absent_count
first_batch_present_user0_count: $first_batch_present_count
remaining_review_candidate_count: ${#REMAINING_REVIEW_CANDIDATES[@]}
remaining_review_candidates_present_user0_count: $remaining_present_count
second_batch_planned_count: ${#SECOND_BATCH_ORDER[@]}
second_batch_ready_count: $second_batch_ready_count
second_batch_not_ready_count: $second_batch_not_ready_count
deferred_candidate_count: ${#DEFERRED_REVIEW[@]}
final_result: $final_result
safety_boundary: command planning only, no uninstall, no restore, no disable, no package data clearing, no flashing, no bootloader action, no userdata erase
EOF_SUMMARY

  cp "$SUMMARY_FILE" "$EVIDENCE_DIR/shareable/summary.txt"
  cp "$FIRST_BATCH_TSV" "$EVIDENCE_DIR/shareable/first-batch-state.tsv"
  cp "$CANDIDATE_TSV" "$EVIDENCE_DIR/shareable/remaining-review-candidates.tsv"
  cp "$COMMAND_TSV" "$EVIDENCE_DIR/shareable/second-batch-command-plan.tsv"
  cp "$DEFERRED_TSV" "$EVIDENCE_DIR/shareable/deferred-review-candidates.tsv"

  cat > "$STATUS_DOC" <<EOF_DOC
# Clean Stock Second Batch Restore-First Command Plan, 2026-05-17

## Current status

Step 37 generated a restore-first command plan for the next clean-stock review-only candidate group.

This is command planning only.

Step 37 did not execute uninstall, restore, disable, package data clearing, force-stop, settings mutation, bootloader unlock, flashing, downgrade, userdata erase, DSU installation, Google application sideloading, Xiaomi flash script execution, or relock.

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

## First batch retained state

The first batch remains absent for Android user 0.

\`\`\`text
$(column -t -s $'\t' "$FIRST_BATCH_TSV")
\`\`\`

## Remaining review-only candidates checked

\`\`\`text
$(column -t -s $'\t' "$CANDIDATE_TSV")
\`\`\`

## Second batch command plan

The second batch order is intentionally focused on non-wallpaper review-only candidates first.

\`\`\`text
$(column -t -s $'\t' "$COMMAND_TSV")
\`\`\`

## Deferred review candidates

\`\`\`text
$(column -t -s $'\t' "$DEFERRED_TSV")
\`\`\`

## Restore-first rule

Every planned second-batch package has a restore command documented before any future removal command is considered.

Restore pattern:

\`\`\`text
adb shell cmd package install-existing --user 0 PACKAGE_NAME
\`\`\`

Removal pattern, not approved by Step 37:

\`\`\`text
adb shell pm uninstall --user 0 PACKAGE_NAME
\`\`\`

## Safety boundary

The generated second-batch commands are not approved for execution by this step.

Future execution must continue one package at a time, with explicit approval and post-change phone checks.

## Current conclusion

\`\`\`text
final_result: $final_result
\`\`\`

If the final result is \`second_batch_restore_first_plan_ready\`, the next package test may proceed with the first planned second-batch package only.
EOF_DOC

  tar -C "$EVIDENCE_DIR/shareable" -czf "$SHAREABLE_PATH" .
  write_manifest_entry

  log "wrote private evidence outside repo: $EVIDENCE_DIR"
  log "wrote shareable bundle: $SHAREABLE_PATH"
  log "wrote status document: $STATUS_DOC"
  log "updated manifest: $MANIFEST"
  log "Step 37 complete: $final_result"

  cat <<EOF_NEXT

Step 37 output files:
  $STATUS_DOC
  $SHAREABLE_PATH
  $MANIFEST

Next local verification command:
  cd $ROOT_DIR
  git status --short
  sed -n '1,360p' $STATUS_DOC
  grep '$SHAREABLE_NAME' $MANIFEST || true
EOF_NEXT
}

main "$@"
