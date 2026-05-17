#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-dynsystem-apk-official-tool-decode-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"

ADB_SERIAL=""
ADB_READY="no"
APK_DEVICE_PATH=""
APK_LOCAL_PATH="${OUT_DIR}/02-apk/DynamicSystemInstallationService.apk"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-apk,03-tools,04-aapt2,05-aapt,06-apkanalyzer,07-strings,08-summary}

log_section() {
  local title="$1"
  echo
  echo "== ${title} =="
  date -Is
  echo
}

adb_cmd() {
  if [ -n "${ADB_SERIAL}" ]; then
    adb -s "${ADB_SERIAL}" "$@"
  else
    adb "$@"
  fi
}

wait_for_adb_device() {
  local log_file="$1"
  local attempts=36
  local sleep_seconds=5
  local attempt=1

  {
    log_section "adb wait"
    echo "This script is read-only."
    echo "It pulls the installed DSU APK from read-only /system and decodes it locally."
    echo "It does not start DSU, install DSU, flash, unlock, or change settings."
    echo
    echo "Connect and unlock the phone if needed."
    echo
    echo "== restarting adb server =="
    adb kill-server 2>&1 || true
    sleep 2
    adb start-server 2>&1 || true
    echo
  } | tee "${log_file}"

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

run_host_to_file() {
  local output_file="$1"
  shift
  local title="$1"
  shift

  {
    log_section "${title}"
    "$@" 2>&1 || true
  } >> "${output_file}"
}

run_aapt2() {
  local output_file="$1"
  shift
  local title="$1"
  shift

  if command -v aapt2 >/dev/null 2>&1; then
    run_host_to_file "${output_file}" "${title}" aapt2 "$@"
  else
    {
      log_section "${title}"
      echo "aapt2 not found"
    } >> "${output_file}"
  fi
}

run_aapt() {
  local output_file="$1"
  shift
  local title="$1"
  shift

  if command -v aapt >/dev/null 2>&1; then
    run_host_to_file "${output_file}" "${title}" aapt "$@"
  else
    {
      log_section "${title}"
      echo "aapt not found"
    } >> "${output_file}"
  fi
}

run_apkanalyzer() {
  local output_file="$1"
  shift
  local title="$1"
  shift

  if command -v apkanalyzer >/dev/null 2>&1; then
    run_host_to_file "${output_file}" "${title}" apkanalyzer "$@"
  else
    {
      log_section "${title}"
      echo "apkanalyzer not found"
    } >> "${output_file}"
  fi
}

{
  echo "citrine dynsystem APK official-tool decode"
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
  for tool in adb aapt2 aapt apkanalyzer unzip zipinfo strings grep sed awk tar sha256sum file; do
    printf '%-14s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
  echo
  if command -v aapt2 >/dev/null 2>&1; then aapt2 version 2>&1 || true; fi
  if command -v aapt >/dev/null 2>&1; then aapt version 2>&1 || true; fi
  if command -v apkanalyzer >/dev/null 2>&1; then apkanalyzer --version 2>&1 || true; fi
} | tee "${OUT_DIR}/03-tools/tool-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-wait.txt" || true

{
  log_section "adb final state"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" = "yes" ]; then
  {
    log_section "locate dynsystem package"
    echo "== pm path com.android.dynsystem =="
    adb_cmd shell pm path com.android.dynsystem 2>&1 || true
    echo
    echo "== dumpsys package path hints =="
    adb_cmd shell dumpsys package com.android.dynsystem 2>/dev/null | grep -Ei 'codePath|resourcePath|legacyNativeLibraryDir|primaryCpuAbi|versionName|versionCode' || true
  } | tee "${OUT_DIR}/02-apk/package-location.txt"

  APK_DEVICE_PATH="$(adb_cmd shell pm path com.android.dynsystem 2>/dev/null | tr -d '\r' | sed -n 's/^package://p' | head -n 1)"

  if [ -z "${APK_DEVICE_PATH}" ]; then
    APK_DEVICE_PATH="/system/priv-app/DynamicSystemInstallationService/DynamicSystemInstallationService.apk"
  fi

  {
    log_section "pull apk read-only"
    echo "apk_device_path: ${APK_DEVICE_PATH}"
    echo "apk_local_path: ${APK_LOCAL_PATH}"
    adb_cmd pull "${APK_DEVICE_PATH}" "${APK_LOCAL_PATH}" 2>&1 || true
    echo
    if [ -f "${APK_LOCAL_PATH}" ]; then
      ls -lh "${APK_LOCAL_PATH}"
      file "${APK_LOCAL_PATH}"
      sha256sum "${APK_LOCAL_PATH}"
    else
      echo "apk pull failed"
    fi
  } | tee "${OUT_DIR}/02-apk/apk-pull.txt"

  if [ -f "${APK_LOCAL_PATH}" ]; then
    run_host_to_file "${OUT_DIR}/02-apk/apk-zip-listing.txt" "zip listing" unzip -l "${APK_LOCAL_PATH}"
    run_host_to_file "${OUT_DIR}/02-apk/apk-zipinfo.txt" "zipinfo" zipinfo "${APK_LOCAL_PATH}"

    AAPT2_OUT="${OUT_DIR}/04-aapt2/aapt2-output.txt"
    run_aapt2 "${AAPT2_OUT}" "aapt2 dump badging" dump badging "${APK_LOCAL_PATH}"
    run_aapt2 "${AAPT2_OUT}" "aapt2 dump permissions" dump permissions "${APK_LOCAL_PATH}"
    run_aapt2 "${AAPT2_OUT}" "aapt2 dump xmltree manifest" dump xmltree "${APK_LOCAL_PATH}" --file AndroidManifest.xml
    run_aapt2 "${AAPT2_OUT}" "aapt2 dump xmlstrings manifest" dump xmlstrings "${APK_LOCAL_PATH}" --file AndroidManifest.xml

    AAPT_OUT="${OUT_DIR}/05-aapt/aapt-output.txt"
    run_aapt "${AAPT_OUT}" "aapt dump badging" dump badging "${APK_LOCAL_PATH}"
    run_aapt "${AAPT_OUT}" "aapt dump permissions" dump permissions "${APK_LOCAL_PATH}"
    run_aapt "${AAPT_OUT}" "aapt dump xmltree manifest" dump xmltree "${APK_LOCAL_PATH}" AndroidManifest.xml
    run_aapt "${AAPT_OUT}" "aapt dump xmlstrings manifest" dump xmlstrings "${APK_LOCAL_PATH}" AndroidManifest.xml

    APKANALYZER_OUT="${OUT_DIR}/06-apkanalyzer/apkanalyzer-output.txt"
    run_apkanalyzer "${APKANALYZER_OUT}" "apkanalyzer apk summary" apk summary "${APK_LOCAL_PATH}"
    run_apkanalyzer "${APKANALYZER_OUT}" "apkanalyzer manifest print" manifest print "${APK_LOCAL_PATH}"
    run_apkanalyzer "${APKANALYZER_OUT}" "apkanalyzer manifest permissions" manifest permissions "${APK_LOCAL_PATH}"

    {
      log_section "apk strings focused evidence"
      strings -a -n 3 "${APK_LOCAL_PATH}" \
        | grep -Ei 'VerificationActivity|DynamicSystem|dynsystem|START_INSTALL|android.os.image|MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|gsid|gsi|userdata|system\.img|vbmeta|signature|permission|exported|content|file|https|http' \
        | sort -u || true
    } | tee "${OUT_DIR}/07-strings/focused-strings.txt"

    {
      log_section "focused decode hints"
      echo "== aapt2 focused lines =="
      grep -RniE 'VerificationActivity|START_INSTALL|DEFAULT|scheme|host|mimeType|exported|permission|MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|DynamicSystem' "${OUT_DIR}/04-aapt2" 2>/dev/null || true
      echo
      echo "== aapt focused lines =="
      grep -RniE 'VerificationActivity|START_INSTALL|DEFAULT|scheme|host|mimeType|exported|permission|MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|DynamicSystem' "${OUT_DIR}/05-aapt" 2>/dev/null || true
      echo
      echo "== apkanalyzer focused lines =="
      grep -RniE 'VerificationActivity|START_INSTALL|DEFAULT|scheme|host|mimeType|exported|permission|MANAGE_DYNAMIC_SYSTEM|INSTALL_DYNAMIC_SYSTEM|DynamicSystem' "${OUT_DIR}/06-apkanalyzer" 2>/dev/null || true
    } | tee "${OUT_DIR}/08-summary/focused-decode-hints.txt"
  fi
fi

{
  log_section "summary"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo "apk_device_path: ${APK_DEVICE_PATH}"
  echo "apk_local_path: ${APK_LOCAL_PATH}"
  if [ -f "${APK_LOCAL_PATH}" ]; then
    echo "apk_sha256: $(sha256sum "${APK_LOCAL_PATH}" | awk '{print $1}')"
  else
    echo "apk_sha256: unavailable"
  fi
  echo
  echo "tool availability:"
  for tool in aapt2 aapt apkanalyzer; do
    if command -v "${tool}" >/dev/null 2>&1; then
      echo "${tool}: present"
    else
      echo "${tool}: missing"
    fi
  done
  echo
  echo "read-only checks completed:"
  echo "- pulled installed DSU APK from read-only /system"
  echo "- attempted official-tool manifest decode when tools were present"
  echo "- collected APK strings and focused manifest hints"
  echo
  echo "safety:"
  echo "- no activity started"
  echo "- no DSU installation attempted"
  echo "- no gsi_tool install, enable, wipe, wipe-data, or cancel"
  echo "- no flashing"
  echo "- no bootloader unlock"
  echo "- no settings changes"
} | tee "${OUT_DIR}/08-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
