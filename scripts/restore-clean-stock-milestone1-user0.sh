#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"

REMOVED_PACKAGES=(
  com.miui.analytics
  com.miui.msa.global
  com.miui.thirdappassistant
  com.miui.bugreport
  com.xiaomi.mipicks
  com.xiaomi.discover
  com.miui.videoplayer
  com.miui.yellowpage
  com.mi.android.globalFileexplorer
  com.mi.appfinder
  com.mi.globalminusscreen
  com.mi.healthglobal
  com.miui.android.fashiongallery
  com.miui.cleaner
  com.miui.fm
  com.miui.fmservice
  com.miui.player
  com.xiaomi.calendar
  com.android.thememanager
  com.miui.gallery
  com.miui.miservice
  com.xiaomi.glgm
)

DISABLED_PACKAGES=(
  com.miui.calculator
  com.miui.compass
  com.miui.notes
  com.xiaomi.scanner
)

usage() {
  cat <<'USAGE'
Usage:
  scripts/restore-clean-stock-milestone1-user0.sh --dry-run
  scripts/restore-clean-stock-milestone1-user0.sh --execute

Purpose:
  Restore the clean-stock Milestone 1 user 0 package state.

Safety:
  --dry-run prints commands only.
  --execute restores removed packages with install-existing and re-enables disabled packages.
USAGE
}

require_adb_device() {
  adb get-state >/dev/null
  state="$(adb get-state 2>/dev/null | tr -d '\r')"
  if [ "$state" != "device" ]; then
    echo "ERROR: adb state is not device: $state" >&2
    exit 1
  fi
}

print_restore_commands() {
  echo "== restore removed packages =="
  for pkg in "${REMOVED_PACKAGES[@]}"; do
    echo "adb shell cmd package install-existing --user 0 $pkg"
  done

  echo
  echo "== enable disabled packages =="
  for pkg in "${DISABLED_PACKAGES[@]}"; do
    echo "adb shell pm enable --user 0 $pkg"
  done
}

execute_restore_commands() {
  echo "== restoring removed packages =="
  for pkg in "${REMOVED_PACKAGES[@]}"; do
    echo
    echo "command: adb shell cmd package install-existing --user 0 $pkg"
    adb shell cmd package install-existing --user 0 "$pkg" || true
  done

  echo
  echo "== enabling disabled packages =="
  for pkg in "${DISABLED_PACKAGES[@]}"; do
    echo
    echo "command: adb shell pm enable --user 0 $pkg"
    adb shell pm enable --user 0 "$pkg" || true
  done

  echo
  echo "== post-restore package state =="
  for pkg in "${REMOVED_PACKAGES[@]}" "${DISABLED_PACKAGES[@]}"; do
    present="no"
    enabled="no"
    disabled="no"

    adb shell pm list packages --user 0 "$pkg" 2>/dev/null | tr -d '\r' | grep -Fxq "package:$pkg" && present="yes"
    adb shell pm list packages -e --user 0 "$pkg" 2>/dev/null | tr -d '\r' | grep -Fxq "package:$pkg" && enabled="yes"
    adb shell pm list packages -d --user 0 "$pkg" 2>/dev/null | tr -d '\r' | grep -Fxq "package:$pkg" && disabled="yes"

    printf '%-45s present_user0=%-3s enabled_user0=%-3s disabled_user0=%s\n' \
      "$pkg" "$present" "$enabled" "$disabled"
  done
}

case "$MODE" in
  --dry-run)
    print_restore_commands
    ;;
  --execute)
    require_adb_device
    execute_restore_commands
    ;;
  *)
    usage
    exit 1
    ;;
esac
