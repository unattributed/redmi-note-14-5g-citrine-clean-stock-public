#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-dsu-component-inspection-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"

ADB_SERIAL=""
ADB_READY="no"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-package,03-intents,04-binaries,05-services,06-settings-props,07-summary}

log_line() {
  local file="$1"
  shift
  echo "$@" | tee -a "${file}"
}

log_section() {
  local file="$1"
  local title="$2"
  {
    echo
    echo "== ${title} =="
    date -Is
    echo
  } | tee -a "${file}"
}

adb_cmd() {
  if [ -n "${ADB_SERIAL}" ]; then
    adb -s "${ADB_SERIAL}" "$@"
  else
    adb "$@"
  fi
}

capture_adb() {
  local outfile="$1"
  shift
  {
    echo "command: adb $*"
    adb_cmd "$@" 2>&1 || true
  } | tee -a "${outfile}"
}

capture_shell() {
  local outfile="$1"
  shift
  {
    echo "command: adb shell $*"
    adb_cmd shell "$@" 2>&1 || true
  } | tee -a "${outfile}"
}

wait_for_adb_device() {
  local outfile="$1"
  local attempts=36
  local sleep_seconds=5
  local attempt=1

  log_section "${outfile}" "adb reconnect safe wait"
  log_line "${outfile}" "This step is read-only. It does not install DSU, flash, unlock, or change settings."
  log_line "${outfile}" "Connect the phone by USB, unlock the screen, and approve USB debugging if prompted."
  log_line "${outfile}" ""

  {
    echo "== restarting adb server =="
    adb kill-server 2>&1 || true
    sleep 2
    adb start-server 2>&1 || true
    echo
  } | tee -a "${outfile}"

  while [ "${attempt}" -le "${attempts}" ]; do
    {
      echo "attempt ${attempt}/${attempts}"
      echo "-- adb devices -l --"
      adb devices -l 2>&1 || true
      echo
    } | tee -a "${outfile}"

    ADB_SERIAL="$(adb devices 2>/dev/null | awk '$2 == "device" {print $1; exit}')"

    if [ -n "${ADB_SERIAL}" ]; then
      ADB_READY="yes"
      log_line "${outfile}" "adb authorized device found: ${ADB_SERIAL}"
      return 0
    fi

    if adb devices 2>/dev/null | awk '$2 == "unauthorized" {found=1} END {exit found ? 0 : 1}'; then
      log_line "${outfile}" "status: unauthorized"
      log_line "${outfile}" "action: approve the USB debugging prompt on the phone."
    elif adb devices 2>/dev/null | awk '$2 == "offline" {found=1} END {exit found ? 0 : 1}'; then
      log_line "${outfile}" "status: offline"
      log_line "${outfile}" "action: reconnect USB and unlock the phone."
    else
      log_line "${outfile}" "status: no authorized adb device yet"
    fi

    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  ADB_READY="no"
  log_line "${outfile}" "adb device did not become ready within the wait window."
  return 1
}

{
  echo "citrine dsu component inspection"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
  echo "safety: read-only adb inspection only"
} | tee "${OUT_DIR}/00-context/run-context.txt"

{
  echo "== host baseline =="
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  df -h /home "${PROJECT_DIR}" "${EVIDENCE_ROOT}" 2>/dev/null || true
} | tee "${OUT_DIR}/00-context/host-baseline.txt"

{
  echo "== tool baseline =="
  for tool in adb git grep sed awk sha256sum tar date; do
    printf '%-14s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
  git --version 2>&1 || true
} | tee "${OUT_DIR}/00-context/tool-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-wait.txt" || true

{
  echo "== adb final state =="
  date -Is
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" != "yes" ]; then
  {
    echo "== summary =="
    date -Is
    echo "adb_ready: ${ADB_READY}"
    echo "result: adb unavailable, DSU component inspection skipped"
    echo "safety: no phone changes attempted"
  } | tee "${OUT_DIR}/07-summary/summary.txt"

  cd "${EVIDENCE_ROOT}" || exit 1
  tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"
  echo
  echo "upload this file:"
  echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
  exit 0
fi

PACKAGE_OUT="${OUT_DIR}/02-package/dynsystem-package-inspection.txt"
log_section "${PACKAGE_OUT}" "package inventory"
capture_shell "${PACKAGE_OUT}" pm list packages -f
capture_shell "${PACKAGE_OUT}" pm list packages -f com.android.dynsystem
capture_shell "${PACKAGE_OUT}" pm path com.android.dynsystem
capture_shell "${PACKAGE_OUT}" dumpsys package com.android.dynsystem

{
  echo "== focused dynsystem package lines =="
  date -Is
  echo
  grep -nEi 'Package \[|userId=|codePath=|resourcePath=|legacyNativeLibraryDir|versionCode=|targetSdk=|Activities:|Receivers:|Services:|Permissions:|requested permissions:|install permissions:|android\.os\.image|dynamic|dynsystem|gsi|dsu|START_INSTALL|MANAGE_DYNAMIC_SYSTEM|BIND_DYNAMIC_SYSTEM' "${PACKAGE_OUT}" || true
} | tee "${OUT_DIR}/02-package/dynsystem-focused-lines.txt"

INTENT_OUT="${OUT_DIR}/03-intents/dsu-intent-resolution.txt"
log_section "${INTENT_OUT}" "DSU intent resolution"
for action in \
  android.os.image.action.START_INSTALL \
  android.os.image.action.START_INSTALL_DYNAMIC_SYSTEM \
  android.settings.DYNAMIC_SYSTEM_SETTINGS \
  com.android.dynsystem.action.START_INSTALL \
  com.android.dynsystem.action.LAUNCH \
  android.intent.action.MAIN
  do
    {
      echo "## action: ${action}"
      echo "-- resolve-activity --"
    } | tee -a "${INTENT_OUT}"
    capture_shell "${INTENT_OUT}" cmd package resolve-activity --brief -a "${action}"
    {
      echo "-- query-activities --"
    } | tee -a "${INTENT_OUT}"
    capture_shell "${INTENT_OUT}" cmd package query-activities --brief -a "${action}"
    echo | tee -a "${INTENT_OUT}"
  done

{
  echo "== package specific activity and service attempts =="
  date -Is
  echo
} | tee "${OUT_DIR}/03-intents/package-specific-resolution.txt"
capture_shell "${OUT_DIR}/03-intents/package-specific-resolution.txt" cmd package resolve-activity --brief -p com.android.dynsystem -a android.intent.action.MAIN
capture_shell "${OUT_DIR}/03-intents/package-specific-resolution.txt" cmd package query-activities --brief -p com.android.dynsystem -a android.intent.action.MAIN

BIN_OUT="${OUT_DIR}/04-binaries/dsu-binary-inspection.txt"
log_section "${BIN_OUT}" "DSU and GSI binary inventory"
for remote_path in \
  /system/bin/gsi_tool \
  /system/bin/gsid \
  /system/etc/init/gsid.rc \
  /system/priv-app/DynamicSystemInstallationService/DynamicSystemInstallationService.apk \
  /system/lib64/gsi_aidl_interface-cpp.so \
  /system/lib64/libgsi.so \
  /apex/com.android.gsid \
  /apex/com.android.gsid/bin/gsi_tool \
  /apex/com.android.gsid/bin/gsid
  do
    {
      echo "## ${remote_path}"
    } | tee -a "${BIN_OUT}"
    capture_shell "${BIN_OUT}" ls -l "${remote_path}"
    capture_shell "${BIN_OUT}" toybox stat "${remote_path}"
    capture_shell "${BIN_OUT}" sh -c "command -v sha256sum >/dev/null 2>&1 && sha256sum '${remote_path}' || true"
    echo | tee -a "${BIN_OUT}"
  done

HELP_OUT="${OUT_DIR}/04-binaries/gsi-tool-help.txt"
log_section "${HELP_OUT}" "gsi_tool help only"
capture_shell "${HELP_OUT}" sh -c "/system/bin/gsi_tool --help 2>&1 || /system/bin/gsi_tool help 2>&1 || true"
capture_shell "${HELP_OUT}" sh -c "/system/bin/gsi_tool 2>&1 | head -n 120 || true"

SERVICE_OUT="${OUT_DIR}/05-services/dsu-service-inspection.txt"
log_section "${SERVICE_OUT}" "service and process inspection"
capture_shell "${SERVICE_OUT}" service list
capture_shell "${SERVICE_OUT}" sh -c "service list | grep -Ei 'gsi|dynamic|dynsystem|image' || true"
capture_shell "${SERVICE_OUT}" cmd -l
capture_shell "${SERVICE_OUT}" sh -c "cmd -l | grep -Ei 'gsi|dynamic|dynsystem|image' || true"
capture_shell "${SERVICE_OUT}" dumpsys activity services com.android.dynsystem
capture_shell "${SERVICE_OUT}" dumpsys activity services
capture_shell "${SERVICE_OUT}" sh -c "ps -A | grep -Ei 'gsi|gsid|dynsystem|dynamic' || true"

SETTINGS_OUT="${OUT_DIR}/06-settings-props/dsu-settings-and-props.txt"
log_section "${SETTINGS_OUT}" "settings and properties"
capture_shell "${SETTINGS_OUT}" sh -c "settings list global | grep -Ei 'dynamic|gsi|dsu|system_image|ota' || true"
capture_shell "${SETTINGS_OUT}" sh -c "settings list secure | grep -Ei 'dynamic|gsi|dsu|system_image|ota' || true"
capture_shell "${SETTINGS_OUT}" sh -c "settings list system | grep -Ei 'dynamic|gsi|dsu|system_image|ota' || true"
capture_shell "${SETTINGS_OUT}" sh -c "getprop | grep -Ei 'dynamic_system|dynsystem|gsi|dsu|virtual_ab|treble|vndk|vbmeta|verity' | sort || true"

SUMMARY="${OUT_DIR}/07-summary/summary.txt"
{
  echo "== DSU component inspection summary =="
  date -Is
  echo
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo

  if grep -q 'package:com.android.dynsystem' "${PACKAGE_OUT}" 2>/dev/null; then
    echo "dynsystem_package_present: yes"
  else
    echo "dynsystem_package_present: no"
  fi

  if grep -q '/system/bin/gsi_tool' "${BIN_OUT}" 2>/dev/null; then
    echo "gsi_tool_path_checked: yes"
  else
    echo "gsi_tool_path_checked: no"
  fi

  if grep -q '/system/etc/init/gsid.rc' "${BIN_OUT}" 2>/dev/null; then
    echo "gsid_init_rc_checked: yes"
  else
    echo "gsid_init_rc_checked: no"
  fi

  if grep -q 'No activity found' "${INTENT_OUT}" 2>/dev/null; then
    echo "public_dsu_activity_missing_or_unresolved: yes"
  else
    echo "public_dsu_activity_missing_or_unresolved: no_or_inconclusive"
  fi

  echo
  echo "interpretation: read-only evidence only, review package dump and gsi_tool help before any DSU action"
  echo
  echo "safety:"
  echo "no DSU installation attempted"
  echo "no bootloader unlock attempted"
  echo "no flashing attempted"
  echo "no settings changes attempted"
} | tee "${SUMMARY}"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
