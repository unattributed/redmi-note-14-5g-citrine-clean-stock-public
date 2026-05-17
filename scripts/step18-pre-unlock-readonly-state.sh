#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-pre-unlock-readonly-state-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"

ADB_SERIAL=""
ADB_READY="no"
FASTBOOT_READY="no"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-fastboot,03-summary}

log_section_to_file() {
  local file_path="$1"
  local title="$2"
  {
    echo
    echo "== ${title} =="
    date -Is
    echo
  } | tee -a "${file_path}"
}

append_cmd_to_file() {
  local file_path="$1"
  shift
  "$@" 2>&1 | tee -a "${file_path}"
}

adb_cmd() {
  if [ -n "${ADB_SERIAL}" ]; then
    adb -s "${ADB_SERIAL}" "$@"
  else
    adb "$@"
  fi
}

wait_for_adb_device() {
  local file_path="$1"

  : > "${file_path}"
  log_section_to_file "${file_path}" "adb wait"

  {
    echo "This script is read-only."
    echo "It does not unlock, flash, erase data, start DSU, or change settings."
    echo
    echo "Connect and unlock the phone if needed."
    echo
    echo "== restarting adb server =="
  } | tee -a "${file_path}"

  adb kill-server 2>&1 | tee -a "${file_path}" || true
  sleep 2
  adb start-server 2>&1 | tee -a "${file_path}" || true
  echo | tee -a "${file_path}"

  for attempt in $(seq 1 36); do
    echo "attempt ${attempt}/36" | tee -a "${file_path}"
    echo "-- adb devices -l --" | tee -a "${file_path}"
    adb devices -l 2>&1 | tee -a "${file_path}" || true
    echo | tee -a "${file_path}"

    ADB_SERIAL="$(adb devices 2>/dev/null | awk '$2 == "device" {print $1; exit}')"

    if [ -n "${ADB_SERIAL}" ]; then
      ADB_READY="yes"
      echo "adb authorized device found: ${ADB_SERIAL}" | tee -a "${file_path}"
      return 0
    fi

    if adb devices 2>/dev/null | awk '$2 == "unauthorized" {found=1} END {exit found ? 0 : 1}'; then
      echo "status: unauthorized, approve the USB debugging prompt on the phone" | tee -a "${file_path}"
    elif adb devices 2>/dev/null | awk '$2 == "offline" {found=1} END {exit found ? 0 : 1}'; then
      echo "status: offline, reconnect USB and unlock the phone" | tee -a "${file_path}"
    else
      echo "status: no authorized adb device yet" | tee -a "${file_path}"
    fi

    echo | tee -a "${file_path}"
    sleep 5
  done

  ADB_READY="no"
  ADB_SERIAL=""
  echo "adb device did not become ready within the wait window" | tee -a "${file_path}"
  return 1
}

wait_for_fastboot_device() {
  local file_path="$1"

  : > "${file_path}"
  log_section_to_file "${file_path}" "fastboot wait"

  for attempt in $(seq 1 30); do
    echo "attempt ${attempt}/30" | tee -a "${file_path}"
    fastboot devices 2>&1 | tee -a "${file_path}" || true
    echo | tee -a "${file_path}"

    if fastboot devices 2>/dev/null | awk 'NF >= 1 {found=1} END {exit found ? 0 : 1}'; then
      FASTBOOT_READY="yes"
      echo "fastboot device detected" | tee -a "${file_path}"
      return 0
    fi

    sleep 3
  done

  FASTBOOT_READY="no"
  echo "fastboot device was not detected" | tee -a "${file_path}"
  return 1
}

{
  echo "citrine pre-unlock read-only state"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
} | tee "${OUT_DIR}/00-context/run-context.txt"

{
  echo
  echo "== host baseline =="
  date -Is
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  df -h /home "${PROJECT_DIR}" "${EVIDENCE_ROOT}" 2>/dev/null || true
  echo
  echo "== tool baseline =="
  for tool in adb fastboot sha256sum tar; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
  fastboot --version 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/00-context/host-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-wait.txt" || true

{
  echo
  echo "== adb read-only state =="
  date -Is
  echo
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
  echo

  if [ "${ADB_READY}" = "yes" ]; then
    echo "== selected getprop values =="
    for prop in \
      ro.product.marketname \
      ro.product.model \
      ro.product.device \
      ro.product.board \
      ro.board.platform \
      ro.hardware \
      ro.build.version.release \
      ro.build.version.sdk \
      ro.build.version.security_patch \
      ro.treble.enabled \
      ro.boot.dynamic_partitions \
      ro.virtual_ab.enabled \
      ro.virtual_ab.compression.enabled \
      ro.boot.slot_suffix \
      ro.boot.verifiedbootstate \
      ro.boot.vbmeta.device_state \
      ro.boot.flash.locked \
      ro.boot.veritymode \
      ro.boot.avb_version
    do
      value="$(adb_cmd shell getprop "${prop}" 2>/dev/null || true)"
      echo "${prop}=${value}"
    done

    echo
    echo "== data filesystem =="
    adb_cmd shell df -T /data 2>&1 || adb_cmd shell df /data 2>&1 || true

    echo
    echo "== battery and boot status hints =="
    adb_cmd shell dumpsys battery 2>&1 | head -n 80 || true
  fi
} 2>&1 | tee "${OUT_DIR}/01-adb/adb-readonly-state.txt"

if [ "${ADB_READY}" = "yes" ]; then
  {
    echo
    echo "== reboot to bootloader =="
    date -Is
    echo
    echo "Rebooting to bootloader for read-only fastboot getvar capture."
    echo "This does not unlock, flash, erase data, or change settings."
  } 2>&1 | tee "${OUT_DIR}/02-fastboot/fastboot-note.txt"

  adb_cmd reboot bootloader 2>&1 | tee -a "${OUT_DIR}/02-fastboot/fastboot-note.txt" || true
  sleep 5

  wait_for_fastboot_device "${OUT_DIR}/02-fastboot/fastboot-wait.txt" || true

  {
    echo
    echo "== fastboot read-only state =="
    date -Is
    echo
    echo "fastboot_ready: ${FASTBOOT_READY}"
    echo
    if [ "${FASTBOOT_READY}" = "yes" ]; then
      echo "== fastboot devices =="
      fastboot devices 2>&1 || true
      echo

      echo "== selected fastboot getvars =="
      for var in product current-slot slot-count unlocked secure anti version-bootloader version-baseband is-userspace max-download-size; do
        echo "## ${var}"
        fastboot getvar "${var}" 2>&1 || true
        echo
      done
    fi
  } 2>&1 | tee "${OUT_DIR}/02-fastboot/fastboot-readonly-state.txt"

  if [ "${FASTBOOT_READY}" = "yes" ]; then
    fastboot reboot 2>&1 | tee -a "${OUT_DIR}/02-fastboot/fastboot-note.txt" || true

    {
      echo
      echo "== adb after fastboot reboot =="
      date -Is
      echo
      echo "Waiting briefly for Android to return."
      adb wait-for-device 2>&1 || true
      adb devices -l 2>&1 || true
    } 2>&1 | tee "${OUT_DIR}/02-fastboot/adb-after-fastboot-reboot.txt"
  fi
fi

{
  echo
  echo "== summary =="
  date -Is
  echo
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo "fastboot_ready: ${FASTBOOT_READY}"
  echo
  echo "safety:"
  echo "- no unlock"
  echo "- no flashing"
  echo "- no userdata erase"
  echo "- no DSU install"
  echo "- read-only adb and fastboot queries only"
} 2>&1 | tee "${OUT_DIR}/03-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
