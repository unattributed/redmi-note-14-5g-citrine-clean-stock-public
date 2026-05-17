#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-dsu-readiness-probe-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"

ADB_SERIAL=""
ADB_READY="no"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-packages,03-activities,04-filesystem,05-properties,06-settings,07-summary}

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

capture_to_file() {
  local file_path="$1"
  shift
  "$@" 2>&1 | tee "${file_path}"
}

wait_for_adb_device() {
  local log_file="$1"
  local attempts=36
  local sleep_seconds=5
  local attempt=1

  : > "${log_file}"

  {
    log_section "adb wait"
    echo "This probe is read-only."
    echo "Connect the phone by USB, unlock the screen, and approve USB debugging if prompted."
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
      {
        echo "adb authorized device found: ${ADB_SERIAL}"
        echo
      } | tee -a "${log_file}"
      return 0
    fi

    if adb devices 2>/dev/null | awk '$2 == "unauthorized" {found=1} END {exit found ? 0 : 1}'; then
      {
        echo "status: unauthorized"
        echo "action: approve the USB debugging prompt on the phone."
        echo
      } | tee -a "${log_file}"
    elif adb devices 2>/dev/null | awk '$2 == "offline" {found=1} END {exit found ? 0 : 1}'; then
      {
        echo "status: offline"
        echo "action: unplug and reconnect USB, then unlock the phone."
        echo
      } | tee -a "${log_file}"
    else
      {
        echo "status: no authorized adb device yet"
        echo
      } | tee -a "${log_file}"
    fi

    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  ADB_READY="no"
  return 1
}

{
  echo "citrine dsu readiness probe"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
} 2>&1 | tee "${OUT_DIR}/00-context/run-context.txt"

{
  log_section "host baseline"
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  for tool in adb grep sed awk tar sha256sum; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/00-context/host-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-wait.txt" || true

{
  log_section "adb final state"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" != "yes" ]; then
  {
    log_section "summary"
    echo "ADB was not ready. DSU readiness probe could not continue."
    echo "No phone changes were attempted."
  } 2>&1 | tee "${OUT_DIR}/07-summary/summary.txt"

  cd "${EVIDENCE_ROOT}" || exit 1
  tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"
  echo
  echo "upload this file:"
  echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
  exit 0
fi

{
  log_section "package discovery"
  echo "== packages matching dsu, gsi, dynsystem, dynamic =="
  adb_cmd shell pm list packages 2>/dev/null | grep -Ei 'dsu|gsi|dynsystem|dynamic' || true
  echo
  echo "== package path hints =="
  for pkg in \
    com.android.dynsystem \
    com.android.gsid \
    com.google.android.gsf \
    com.android.updater
  do
    echo "## ${pkg}"
    adb_cmd shell pm path "${pkg}" 2>&1 || true
    echo
  done
  echo "== feature hints =="
  adb_cmd shell pm list features 2>/dev/null | grep -Ei 'dynamic|dsu|gsi|treble' || true
} 2>&1 | tee "${OUT_DIR}/02-packages/package-discovery.txt"

{
  log_section "activity and intent discovery"
  echo "== resolve START_INSTALL activity =="
  adb_cmd shell cmd package resolve-activity --brief -a android.os.image.action.START_INSTALL 2>&1 || true
  echo
  echo "== query START_INSTALL activities =="
  adb_cmd shell cmd package query-intent-activities --brief -a android.os.image.action.START_INSTALL 2>&1 || true
  echo
  echo "== resolve DSU loader aliases =="
  for action in \
    android.os.image.action.START_INSTALL \
    android.settings.DYNAMIC_SYSTEM_SETTINGS \
    com.android.dynsystem.action.START_INSTALL
  do
    echo "## ${action}"
    adb_cmd shell cmd package resolve-activity --brief -a "${action}" 2>&1 || true
    echo
  done
} 2>&1 | tee "${OUT_DIR}/03-activities/activity-intent-discovery.txt"

{
  log_section "filesystem component discovery"
  echo "== candidate files and directories =="
  adb_cmd shell 'for p in \
    /system/bin/gsi_tool \
    /system/bin/gsid \
    /system/bin/dsu \
    /system/bin/dsu_tool \
    /system/etc/permissions/android.software.dynamic_system.xml \
    /system/etc/permissions/android.software.virtualization_framework.xml \
    /apex/com.android.gsid \
    /apex/com.android.virt \
    /metadata/gsi \
    /data/gsi; do ls -ld "$p" 2>&1 || true; done' 2>&1 || true
  echo
  echo "== find gsi and dsu file hints, limited depth =="
  adb_cmd shell 'find /system /apex /metadata /data -maxdepth 4 \( -iname "*gsi*" -o -iname "*dsu*" -o -iname "*dynsystem*" \) 2>/dev/null | head -n 300' 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/04-filesystem/filesystem-component-discovery.txt"

{
  log_section "property discovery"
  echo "== targeted getprop, DSU and compatibility only =="
  adb_cmd shell getprop 2>/dev/null \
    | grep -Ei 'dynamic_system|dynsystem|gsi|dsu|virtual_ab|treble|vndk|dynamic_partitions|verifiedboot|vbmeta|verity|first_api_level|pagesize|abi' \
    | sort || true
} 2>&1 | tee "${OUT_DIR}/05-properties/targeted-properties.txt"

{
  log_section "settings discovery"
  echo "== global settings hints =="
  adb_cmd shell settings list global 2>/dev/null | grep -Ei 'dynamic|gsi|dsu|development|developer' || true
  echo
  echo "== secure settings hints =="
  adb_cmd shell settings list secure 2>/dev/null | grep -Ei 'dynamic|gsi|dsu|development|developer' || true
} 2>&1 | tee "${OUT_DIR}/06-settings/settings-discovery.txt"

{
  log_section "summary"
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  echo "probe outputs:"
  echo "- 02-packages/package-discovery.txt"
  echo "- 03-activities/activity-intent-discovery.txt"
  echo "- 04-filesystem/filesystem-component-discovery.txt"
  echo "- 05-properties/targeted-properties.txt"
  echo "- 06-settings/settings-discovery.txt"
  echo
  echo "safety:"
  echo "no flashing"
  echo "no bootloader unlock"
  echo "no DSU installation"
  echo "no persistent setting changes"
  echo "ADB read-only discovery only"
} 2>&1 | tee "${OUT_DIR}/07-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
