#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-dynsystem-apk-manifest-inspection-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
AXML_HELPER="${PROJECT_DIR}/scripts/lib/axml_manifest_dump.py"

ADB_SERIAL=""
ADB_READY="no"
APK_DEVICE_PATH=""
APK_LOCAL_PATH="${OUT_DIR}/02-apk/DynamicSystemInstallationService.apk"
MANIFEST_RAW="${OUT_DIR}/03-manifest/AndroidManifest.xml"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-apk,03-manifest,04-tools,05-package,06-gsi,07-summary}

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

run_local_to_file() {
  local file_path="$1"
  local title="$2"
  shift 2
  append_header "${file_path}" "${title}"
  "$@" >> "${file_path}" 2>&1 || true
}

run_adb_shell_to_file() {
  local file_path="$1"
  local title="$2"
  shift 2
  append_header "${file_path}" "${title}"
  adb_cmd shell "$@" >> "${file_path}" 2>&1 || true
}

wait_for_adb_device() {
  local attempts=36
  local sleep_seconds=5
  local attempt=1
  local log_file="${OUT_DIR}/01-adb/adb-wait.txt"

  log_section "adb wait" | tee "${log_file}"
  {
    echo "This script is read-only."
    echo "It pulls the installed DSU APK from /system for offline manifest inspection."
    echo "It does not start DSU installation."
    echo "It does not flash, unlock, or change settings."
    echo
    echo "Connect and unlock the phone if needed."
    echo
    echo "== restarting adb server =="
    adb kill-server 2>&1 || true
    sleep 2
    adb start-server 2>&1 || true
    echo
  } | tee -a "${log_file}"

  while [ "${attempt}" -le "${attempts}" ]; do
    {
      echo "attempt ${attempt}/${attempts}"
      echo "-- adb devices -l --"
      adb devices -l 2>&1 || true
      echo
    } | tee -a "${log_file}"

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
  echo "citrine DSU APK manifest inspection"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
  echo "axml_helper: ${AXML_HELPER}"
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
  for tool in adb unzip zipinfo file sha256sum python3 grep sed awk strings aapt aapt2 apkanalyzer jadx apktool; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
  python3 --version 2>&1 || true
  echo
  if [ -f "${AXML_HELPER}" ]; then
    ls -lh "${AXML_HELPER}"
    sha256sum "${AXML_HELPER}"
  else
    echo "missing helper: ${AXML_HELPER}"
  fi
} | tee "${OUT_DIR}/00-context/tool-baseline.txt"

wait_for_adb_device || true

{
  log_section "adb final state"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" = "yes" ]; then
  PACKAGE_FILE="${OUT_DIR}/05-package/dynsystem-package-evidence.txt"
  APK_FILE="${OUT_DIR}/02-apk/apk-baseline.txt"
  MANIFEST_FILE="${OUT_DIR}/03-manifest/manifest-parser-run.txt"
  TOOL_FILE="${OUT_DIR}/04-tools/optional-tool-output.txt"
  GSI_FILE="${OUT_DIR}/06-gsi/gsi-status.txt"

  run_adb_shell_to_file "${PACKAGE_FILE}" "pm path com.android.dynsystem" pm path com.android.dynsystem
  run_adb_shell_to_file "${PACKAGE_FILE}" "dumpsys package com.android.dynsystem" dumpsys package com.android.dynsystem
  run_adb_shell_to_file "${PACKAGE_FILE}" "dumpsys activity intent filters dynsystem excerpt" sh -c "dumpsys package com.android.dynsystem | sed -n '/VerificationActivity/,+80p'"

  APK_DEVICE_PATH="$(adb_cmd shell pm path com.android.dynsystem 2>/dev/null | sed -n 's/^package://p' | tr -d '\r' | head -n 1)"

  {
    log_section "apk pull"
    echo "apk_device_path: ${APK_DEVICE_PATH}"
    echo "apk_local_path: ${APK_LOCAL_PATH}"
    echo
    if [ -z "${APK_DEVICE_PATH}" ]; then
      echo "could not determine APK path for com.android.dynsystem"
    else
      adb_cmd pull "${APK_DEVICE_PATH}" "${APK_LOCAL_PATH}" 2>&1 || true
    fi
  } | tee "${APK_FILE}"

  if [ -f "${APK_LOCAL_PATH}" ]; then
    run_local_to_file "${APK_FILE}" "local apk file baseline" ls -lh "${APK_LOCAL_PATH}"
    run_local_to_file "${APK_FILE}" "local apk file type" file "${APK_LOCAL_PATH}"
    run_local_to_file "${APK_FILE}" "local apk sha256" sha256sum "${APK_LOCAL_PATH}"
    run_local_to_file "${APK_FILE}" "zip inventory" unzip -l "${APK_LOCAL_PATH}"
    run_local_to_file "${APK_FILE}" "apk strings dsu-focused" sh -c "strings -a '${APK_LOCAL_PATH}' | grep -Ei 'dynamic|dynsystem|gsi|dsu|START_INSTALL|VerificationActivity|MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|image' | sort -u | head -n 400"

    unzip -p "${APK_LOCAL_PATH}" AndroidManifest.xml > "${MANIFEST_RAW}" 2>/dev/null || true

    if [ -s "${MANIFEST_RAW}" ] && [ -f "${AXML_HELPER}" ]; then
      {
        log_section "self-contained axml parser"
        python3 "${AXML_HELPER}" \
          "${MANIFEST_RAW}" \
          --json "${OUT_DIR}/03-manifest/manifest-summary.json" \
          --xmlish "${OUT_DIR}/03-manifest/manifest.xmlish" \
          --components "${OUT_DIR}/03-manifest/components.tsv" \
          --verification "${OUT_DIR}/03-manifest/verification-activity-report.txt"
      } | tee "${MANIFEST_FILE}"
    else
      {
        log_section "self-contained axml parser skipped"
        echo "manifest_raw_exists: $([ -s "${MANIFEST_RAW}" ] && echo yes || echo no)"
        echo "helper_exists: $([ -f "${AXML_HELPER}" ] && echo yes || echo no)"
      } | tee "${MANIFEST_FILE}"
    fi

    if command -v aapt >/dev/null 2>&1; then
      run_local_to_file "${TOOL_FILE}" "aapt dump badging" aapt dump badging "${APK_LOCAL_PATH}"
      run_local_to_file "${TOOL_FILE}" "aapt dump xmltree manifest" aapt dump xmltree "${APK_LOCAL_PATH}" AndroidManifest.xml
    fi
    if command -v aapt2 >/dev/null 2>&1; then
      run_local_to_file "${TOOL_FILE}" "aapt2 dump xmltree manifest" aapt2 dump xmltree "${APK_LOCAL_PATH}" AndroidManifest.xml
    fi
    if command -v apkanalyzer >/dev/null 2>&1; then
      run_local_to_file "${TOOL_FILE}" "apkanalyzer manifest print" apkanalyzer manifest print "${APK_LOCAL_PATH}"
    fi
  fi

  run_adb_shell_to_file "${GSI_FILE}" "gsi_tool status only" /system/bin/gsi_tool status
  run_adb_shell_to_file "${GSI_FILE}" "service list dynamic gsi" sh -c "service list | grep -Ei 'dynamic_system|gsi|gsiservice' || true"
  run_adb_shell_to_file "${GSI_FILE}" "process list gsid" sh -c "ps -A | grep -Ei 'gsid|gsi' || true"

  {
    log_section "summary"
    echo "adb_ready: ${ADB_READY}"
    echo "adb_serial: ${ADB_SERIAL}"
    echo "apk_device_path: ${APK_DEVICE_PATH}"
    echo "apk_local_path: ${APK_LOCAL_PATH}"
    if [ -f "${APK_LOCAL_PATH}" ]; then
      echo "apk_sha256: $(sha256sum "${APK_LOCAL_PATH}" | awk '{print $1}')"
    fi
    echo
    echo "verification activity report:"
    sed -n '1,120p' "${OUT_DIR}/03-manifest/verification-activity-report.txt" 2>/dev/null || true
    echo
    echo "gsi_tool status:"
    sed -n '1,80p' "${GSI_FILE}" 2>/dev/null || true
    echo
    echo "safety:"
    echo "- no activity started"
    echo "- no DSU installation attempted"
    echo "- no gsi_tool install, enable, wipe, wipe-data, or cancel"
    echo "- no flashing"
    echo "- no bootloader unlock"
    echo "- no settings changes"
    echo "- APK was pulled from read-only /system for offline inspection"
  } | tee "${OUT_DIR}/07-summary/summary.txt"
else
  {
    log_section "summary"
    echo "adb_ready: ${ADB_READY}"
    echo "adb_serial: ${ADB_SERIAL}"
    echo "ADB was not ready. No APK was pulled."
  } | tee "${OUT_DIR}/07-summary/summary.txt"
fi

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
