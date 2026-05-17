#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-dsu-intent-resolution-followup-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"

ADB_SERIAL=""
ADB_READY="no"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-package,03-resolvers,04-gsi-tool,05-services,06-summary}

log_section() {
  local title="$1"
  echo
  echo "== ${title} =="
  date -Is
  echo
}

append_header() {
  local file_path="$1"
  local title="$2"
  {
    echo
    echo "== ${title} =="
    date -Is
    echo
  } >> "${file_path}"
}

adb_cmd() {
  if [ -n "${ADB_SERIAL}" ]; then
    adb -s "${ADB_SERIAL}" "$@"
  else
    adb "$@"
  fi
}

run_adb_shell_to_file() {
  local output_file="$1"
  local title="$2"
  shift 2

  append_header "${output_file}" "${title}"
  {
    echo "command: adb shell $*"
    echo
    adb_cmd shell "$@" 2>&1 || true
  } >> "${output_file}"
}

run_host_to_file() {
  local output_file="$1"
  local title="$2"
  shift 2

  append_header "${output_file}" "${title}"
  {
    echo "command: $*"
    echo
    "$@" 2>&1 || true
  } >> "${output_file}"
}

wait_for_adb_device() {
  local log_file="$1"
  local attempts=36
  local sleep_seconds=5
  local attempt=1

  {
    log_section "adb wait"
    echo "This script is read-only."
    echo "It does not start DSU installation."
    echo "It does not flash, unlock, or change settings."
    echo
    echo "Connect and unlock the phone if needed."
    echo
    echo "== restarting adb server =="
  } | tee "${log_file}"

  adb kill-server 2>&1 | tee -a "${log_file}" || true
  sleep 2
  adb start-server 2>&1 | tee -a "${log_file}" || true
  echo | tee -a "${log_file}"

  while [ "${attempt}" -le "${attempts}" ]; do
    {
      echo "attempt ${attempt}/${attempts}"
      echo "-- adb devices -l --"
    } | tee -a "${log_file}"

    adb devices -l 2>&1 | tee -a "${log_file}" || true
    echo | tee -a "${log_file}"

    ADB_SERIAL="$(adb devices 2>/dev/null | awk '$2 == "device" {print $1; exit}')"

    if [ -n "${ADB_SERIAL}" ]; then
      ADB_READY="yes"
      echo "adb authorized device found: ${ADB_SERIAL}" | tee -a "${log_file}"
      return 0
    fi

    if adb devices 2>/dev/null | awk '$2 == "unauthorized" {found=1} END {exit found ? 0 : 1}'; then
      echo "status: unauthorized, approve the USB debugging prompt on the phone" | tee -a "${log_file}"
    elif adb devices 2>/dev/null | awk '$2 == "offline" {found=1} END {exit found ? 0 : 1}'; then
      echo "status: offline, reconnect USB and unlock the phone" | tee -a "${log_file}"
    else
      echo "status: no authorized adb device yet" | tee -a "${log_file}"
    fi

    echo | tee -a "${log_file}"
    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  ADB_READY="no"
  return 1
}

{
  echo "citrine DSU intent resolution follow-up"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
} | tee "${OUT_DIR}/00-context/run-context.txt"

{
  log_section "host baseline"
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  df -h /home "${PROJECT_DIR}" "${EVIDENCE_ROOT}" 2>/dev/null || true
} | tee "${OUT_DIR}/00-context/host-baseline.txt"

{
  log_section "tool baseline"
  for tool in adb grep sed awk tar sha256sum; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
} | tee "${OUT_DIR}/00-context/tool-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-wait.txt" || true

{
  log_section "adb final state"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" = "yes" ]; then
  PACKAGE_FILE="${OUT_DIR}/02-package/dynsystem-package-evidence.txt"
  RESOLVER_FILE="${OUT_DIR}/03-resolvers/intent-resolution-evidence.txt"
  GSI_FILE="${OUT_DIR}/04-gsi-tool/gsi-tool-status.txt"
  SERVICES_FILE="${OUT_DIR}/05-services/services-and-processes.txt"

  run_adb_shell_to_file "${PACKAGE_FILE}" "dumpsys package com.android.dynsystem" dumpsys package com.android.dynsystem
  run_adb_shell_to_file "${PACKAGE_FILE}" "package path" pm path com.android.dynsystem
  run_adb_shell_to_file "${PACKAGE_FILE}" "package list entry" pm list packages -f com.android.dynsystem

  run_adb_shell_to_file "${PACKAGE_FILE}" "VerificationActivity focused package excerpt" sh -c "dumpsys package com.android.dynsystem | sed -n '/VerificationActivity/,+80p'"
  run_adb_shell_to_file "${PACKAGE_FILE}" "requested permissions focused excerpt" sh -c "dumpsys package com.android.dynsystem | grep -Ei 'MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|android.permission|VerificationActivity|START_INSTALL' | head -n 240"

  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve START_INSTALL action only" cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL
  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve START_INSTALL with DEFAULT category" cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT
  run_adb_shell_to_file "${RESOLVER_FILE}" "query START_INSTALL with DEFAULT category" cmd package query-intent-activities --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT

  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve START_INSTALL with dummy HTTPS URI" cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d https://example.invalid/nonexistent-gsi/system.img
  run_adb_shell_to_file "${RESOLVER_FILE}" "query START_INSTALL with dummy HTTPS URI" cmd package query-intent-activities --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d https://example.invalid/nonexistent-gsi/system.img

  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve START_INSTALL with dummy file URI" cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d file:///sdcard/Download/nonexistent-system.img
  run_adb_shell_to_file "${RESOLVER_FILE}" "query START_INSTALL with dummy file URI" cmd package query-intent-activities --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d file:///sdcard/Download/nonexistent-system.img

  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve START_INSTALL with dummy content URI" cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d content://example.invalid/nonexistent/system.img
  run_adb_shell_to_file "${RESOLVER_FILE}" "query START_INSTALL with dummy content URI" cmd package query-intent-activities --brief -a android.os.image.action.START_INSTALL -c android.intent.category.DEFAULT -d content://example.invalid/nonexistent/system.img

  run_adb_shell_to_file "${RESOLVER_FILE}" "resolve dynamic system settings action" cmd package resolve-activity --brief -a android.settings.DYNAMIC_SYSTEM_SETTINGS
  run_adb_shell_to_file "${RESOLVER_FILE}" "query dynamic system settings action" cmd package query-intent-activities --brief -a android.settings.DYNAMIC_SYSTEM_SETTINGS

  run_adb_shell_to_file "${GSI_FILE}" "gsi_tool path" ls -l /system/bin/gsi_tool
  run_adb_shell_to_file "${GSI_FILE}" "gsi_tool status only" /system/bin/gsi_tool status

  run_adb_shell_to_file "${SERVICES_FILE}" "service list gsi dynamic" sh -c "service list | grep -Ei 'dynamic_system|gsi|gsiservice' || true"
  run_adb_shell_to_file "${SERVICES_FILE}" "process list gsid" sh -c "ps -A | grep -Ei 'gsid|gsi' || true"
  run_adb_shell_to_file "${SERVICES_FILE}" "init rc gsid" sh -c "ls -l /system/etc/init/gsid.rc /system/bin/gsid 2>&1 || true"
  run_adb_shell_to_file "${SERVICES_FILE}" "selected DSU properties" sh -c "getprop | grep -Ei 'dynamic_system|dynsystem|gsi|dsu|virtual_ab|treble|vndk' | sort || true"

  {
    log_section "summary"
    echo "adb_ready: ${ADB_READY}"
    echo "adb_serial: ${ADB_SERIAL}"
    echo
    echo "read-only checks completed:"
    echo "- package dump for com.android.dynsystem"
    echo "- resolver queries for android.os.image.action.START_INSTALL"
    echo "- resolver queries with DEFAULT category and dummy URI variants"
    echo "- gsi_tool status only"
    echo "- service and process checks"
    echo
    echo "safety:"
    echo "- no activity started"
    echo "- no DSU installation attempted"
    echo "- no gsi_tool install, enable, wipe, wipe-data, or cancel"
    echo "- no flashing"
    echo "- no bootloader unlock"
    echo "- no settings changes"
  } | tee "${OUT_DIR}/06-summary/summary.txt"
else
  {
    log_section "summary"
    echo "adb_ready: ${ADB_READY}"
    echo "adb_serial: ${ADB_SERIAL}"
    echo "ADB was not ready. No phone-side DSU checks were run."
  } | tee "${OUT_DIR}/06-summary/summary.txt"
fi

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
