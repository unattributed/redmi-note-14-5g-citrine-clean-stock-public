#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-gsi-kernel-readiness-reconnect-safe-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
SOURCE_ROOT="${EVIDENCE_ROOT}/source"
KERNEL_DIR="${SOURCE_ROOT}/xiaomi-beryl-u-oss"

ADB_SERIAL=""
ADB_READY="no"
FASTBOOT_READY="no"

mkdir -p "${OUT_DIR}"/{00-context,01-adb,02-treble,03-fastboot,04-kernel-source,05-community-checks,06-summary}
mkdir -p "${SOURCE_ROOT}"

log_line() {
  local log_file="$1"
  shift
  printf '%s\n' "$*" | tee -a "${log_file}"
}

log_blank() {
  local log_file="$1"
  printf '\n' | tee -a "${log_file}"
}

log_section_to_file() {
  local log_file="$1"
  local title="$2"
  {
    echo
    echo "== ${title} =="
    date -Is
    echo
  } | tee -a "${log_file}"
}

log_command_to_file() {
  local log_file="$1"
  shift
  "$@" 2>&1 | tee -a "${log_file}"
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

  : > "${log_file}"

  log_section_to_file "${log_file}" "adb reconnect safe wait"
  log_line "${log_file}" "This step is safe and read-only."
  log_line "${log_file}" "Connect the phone by USB now if it is not already connected."
  log_line "${log_file}" "Unlock the phone screen."
  log_line "${log_file}" "Set USB mode to file transfer if needed."
  log_line "${log_file}" "Approve the USB debugging prompt if Android shows one."
  log_blank "${log_file}"

  log_line "${log_file}" "== restarting adb server =="
  log_command_to_file "${log_file}" adb kill-server || true
  sleep 2
  log_command_to_file "${log_file}" adb start-server || true
  log_blank "${log_file}"

  while [ "${attempt}" -le "${attempts}" ]; do
    log_line "${log_file}" "attempt ${attempt}/${attempts}"
    log_line "${log_file}" "-- adb devices -l --"
    log_command_to_file "${log_file}" adb devices -l || true
    log_blank "${log_file}"

    ADB_SERIAL="$(adb devices 2>/dev/null | awk '$2 == "device" {print $1; exit}')"

    if [ -n "${ADB_SERIAL}" ]; then
      ADB_READY="yes"
      log_line "${log_file}" "adb authorized device found: ${ADB_SERIAL}"
      return 0
    fi

    if adb devices 2>/dev/null | awk '$2 == "unauthorized" {found=1} END {exit found ? 0 : 1}'; then
      log_line "${log_file}" "status: unauthorized"
      log_line "${log_file}" "action: check the phone screen and approve the USB debugging prompt."
      log_line "${log_file}" "tip: if no prompt appears, toggle USB debugging off and on, then reconnect USB."
    elif adb devices 2>/dev/null | awk '$2 == "offline" {found=1} END {exit found ? 0 : 1}'; then
      log_line "${log_file}" "status: offline"
      log_line "${log_file}" "action: unplug and reconnect USB, then unlock the phone."
    else
      log_line "${log_file}" "status: no authorized adb device yet"
    fi

    log_blank "${log_file}"
    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  ADB_READY="no"
  ADB_SERIAL=""
  log_line "${log_file}" "adb device did not become ready within the wait window."
  log_line "${log_file}" "continuing with host-side and kernel-source evidence only."
  return 1
}

wait_for_fastboot_device() {
  local log_file="$1"
  local attempts=30
  local sleep_seconds=3
  local attempt=1

  : > "${log_file}"

  log_section_to_file "${log_file}" "fastboot wait"
  log_line "${log_file}" "Waiting for fastboot device after adb reboot bootloader."
  log_blank "${log_file}"

  while [ "${attempt}" -le "${attempts}" ]; do
    log_line "${log_file}" "attempt ${attempt}/${attempts}"
    log_command_to_file "${log_file}" fastboot devices || true
    log_blank "${log_file}"

    if fastboot devices 2>/dev/null | awk 'NF >= 1 {found=1} END {exit found ? 0 : 1}'; then
      FASTBOOT_READY="yes"
      log_line "${log_file}" "fastboot device detected"
      return 0
    fi

    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  FASTBOOT_READY="no"
  log_line "${log_file}" "fastboot device was not detected."
  return 1
}

write_block() {
  local file_path="$1"
  shift
  {
    "$@"
  } 2>&1 | tee "${file_path}"
}

write_block "${OUT_DIR}/00-context/run-context.txt" bash -c "
  echo 'citrine gsi and kernel source readiness, reconnect safe'
  echo 'timestamp: '"

{
  echo "citrine gsi and kernel source readiness, reconnect safe"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
  echo "source_root: ${SOURCE_ROOT}"
  echo "kernel_dir: ${KERNEL_DIR}"
} 2>&1 | tee "${OUT_DIR}/00-context/run-context.txt"

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
} 2>&1 | tee "${OUT_DIR}/00-context/host-baseline.txt"

{
  echo
  echo "== tool baseline =="
  date -Is
  echo
  for tool in adb fastboot git curl grep sed awk jq python3 timeout; do
    printf '%-12s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  adb version 2>&1 || true
  fastboot --version 2>&1 || true
  git --version 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/00-context/tool-baseline.txt"

wait_for_adb_device "${OUT_DIR}/01-adb/adb-reconnect-wait.txt" || true

{
  echo
  echo "== adb final device state =="
  date -Is
  echo
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo
  adb devices -l 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/01-adb/adb-final-state.txt"

if [ "${ADB_READY}" = "yes" ]; then
  {
    echo
    echo "== read-only Android GSI and Treble properties =="
    date -Is
    echo

    echo "ro.product.marketname=$(adb_cmd shell getprop ro.product.marketname 2>/dev/null || true)"
    echo "ro.product.model=$(adb_cmd shell getprop ro.product.model 2>/dev/null || true)"
    echo "ro.product.device=$(adb_cmd shell getprop ro.product.device 2>/dev/null || true)"
    echo "ro.product.board=$(adb_cmd shell getprop ro.product.board 2>/dev/null || true)"
    echo "ro.board.platform=$(adb_cmd shell getprop ro.board.platform 2>/dev/null || true)"
    echo "ro.hardware=$(adb_cmd shell getprop ro.hardware 2>/dev/null || true)"
    echo "ro.soc.manufacturer=$(adb_cmd shell getprop ro.soc.manufacturer 2>/dev/null || true)"
    echo "ro.soc.model=$(adb_cmd shell getprop ro.soc.model 2>/dev/null || true)"
    echo "ro.build.fingerprint=$(adb_cmd shell getprop ro.build.fingerprint 2>/dev/null || true)"
    echo "ro.build.version.release=$(adb_cmd shell getprop ro.build.version.release 2>/dev/null || true)"
    echo "ro.build.version.sdk=$(adb_cmd shell getprop ro.build.version.sdk 2>/dev/null || true)"
    echo "ro.build.version.security_patch=$(adb_cmd shell getprop ro.build.version.security_patch 2>/dev/null || true)"
    echo "ro.treble.enabled=$(adb_cmd shell getprop ro.treble.enabled 2>/dev/null || true)"
    echo "ro.vndk.version=$(adb_cmd shell getprop ro.vndk.version 2>/dev/null || true)"
    echo "ro.product.cpu.abi=$(adb_cmd shell getprop ro.product.cpu.abi 2>/dev/null || true)"
    echo "ro.product.cpu.abilist=$(adb_cmd shell getprop ro.product.cpu.abilist 2>/dev/null || true)"
    echo "ro.product.cpu.abilist64=$(adb_cmd shell getprop ro.product.cpu.abilist64 2>/dev/null || true)"
    echo "ro.product.cpu.pagesize.max=$(adb_cmd shell getprop ro.product.cpu.pagesize.max 2>/dev/null || true)"
    echo "ro.boot.dynamic_partitions=$(adb_cmd shell getprop ro.boot.dynamic_partitions 2>/dev/null || true)"
    echo "ro.virtual_ab.enabled=$(adb_cmd shell getprop ro.virtual_ab.enabled 2>/dev/null || true)"
    echo "ro.virtual_ab.compression.enabled=$(adb_cmd shell getprop ro.virtual_ab.compression.enabled 2>/dev/null || true)"
    echo "ro.boot.slot_suffix=$(adb_cmd shell getprop ro.boot.slot_suffix 2>/dev/null || true)"
    echo "ro.boot.verifiedbootstate=$(adb_cmd shell getprop ro.boot.verifiedbootstate 2>/dev/null || true)"
    echo "ro.boot.vbmeta.device_state=$(adb_cmd shell getprop ro.boot.vbmeta.device_state 2>/dev/null || true)"
    echo "ro.boot.vbmeta.digest=$(adb_cmd shell getprop ro.boot.vbmeta.digest 2>/dev/null || true)"
    echo "ro.boot.flash.locked=$(adb_cmd shell getprop ro.boot.flash.locked 2>/dev/null || true)"
    echo "ro.boot.veritymode=$(adb_cmd shell getprop ro.boot.veritymode 2>/dev/null || true)"
    echo "ro.boot.avb_version=$(adb_cmd shell getprop ro.boot.avb_version 2>/dev/null || true)"
  } 2>&1 | tee "${OUT_DIR}/02-treble/key-gsi-properties.txt"

  {
    echo
    echo "== filtered getprop for compatibility review =="
    date -Is
    echo

    adb_cmd shell getprop 2>/dev/null \
      | grep -Ei 'treble|vndk|vintf|dynamic|virtual_ab|slot|vbmeta|verifiedboot|verity|avb|cpu|abi|pagesize|system_ext|vendor|product|odm|dlkm|gsi|dsu|ro.product|ro.build|ro.vendor|ro.system|ro.odm|ro.boot' \
      | sort || true
  } 2>&1 | tee "${OUT_DIR}/02-treble/filtered-gsi-getprop.txt"

  {
    echo
    echo "== live partition layout from Android =="
    date -Is
    echo

    echo "== /dev/block/by-name =="
    adb_cmd shell ls -l /dev/block/by-name 2>&1 || true
    echo

    echo "== df -h =="
    adb_cmd shell df -h 2>&1 || true
    echo

    echo "== selected mounts =="
    adb_cmd shell mount 2>&1 \
      | grep -Ei ' /system| /vendor| /product| /system_ext| /odm| /vendor_dlkm| /system_dlkm| /odm_dlkm| /mi_ext| /data|dm-' || true
  } 2>&1 | tee "${OUT_DIR}/02-treble/live-partition-and-mount-layout.txt"

  {
    echo
    echo "== DSU and GSI related package and service hints =="
    date -Is
    echo

    echo "== packages =="
    adb_cmd shell pm list packages 2>/dev/null | grep -Ei 'gsi|dsu|dynamic|updater|overlay' || true
    echo

    echo "== services =="
    adb_cmd shell cmd activity services 2>/dev/null | grep -Ei 'gsi|dsu|dynamic' | head -n 200 || true
  } 2>&1 | tee "${OUT_DIR}/02-treble/dsu-gsi-hints.txt"

  {
    echo
    echo "== fastboot read-only confirmation =="
    date -Is
    echo
    echo "ADB is ready, rebooting to bootloader for read-only fastboot getvar capture."
    echo "This does not flash, unlock, or modify partitions."
  } 2>&1 | tee "${OUT_DIR}/03-fastboot/fastboot-note.txt"

  adb_cmd reboot bootloader 2>&1 | tee -a "${OUT_DIR}/03-fastboot/fastboot-note.txt" || true

  wait_for_fastboot_device "${OUT_DIR}/03-fastboot/fastboot-wait.txt" || true

  if [ "${FASTBOOT_READY}" = "yes" ]; then
    {
      echo
      echo "== fastboot read-only getvars =="
      date -Is
      echo

      echo "== fastboot devices =="
      fastboot devices 2>&1 || true
      echo

      echo "== selected fastboot getvars =="
      for var in product current-slot slot-count unlocked secure anti version-bootloader version-baseband is-userspace max-download-size; do
        echo "## ${var}"
        fastboot getvar "${var}" 2>&1 || true
        echo
      done

      echo "== full fastboot getvar all =="
      fastboot getvar all 2>&1 || true
    } 2>&1 | tee "${OUT_DIR}/03-fastboot/fastboot-readonly-getvars.txt"

    fastboot reboot 2>&1 | tee -a "${OUT_DIR}/03-fastboot/fastboot-note.txt" || true

    {
      echo
      echo "== adb state after fastboot reboot =="
      date -Is
      echo
      echo "Waiting briefly for Android to return."
      adb wait-for-device 2>&1 || true
      adb devices -l 2>&1 || true
    } 2>&1 | tee "${OUT_DIR}/03-fastboot/adb-after-fastboot-reboot.txt"
  else
    {
      echo
      echo "== fastboot skipped or unavailable =="
      date -Is
      echo
      echo "fastboot_ready: ${FASTBOOT_READY}"
      echo "If the phone is still on the bootloader screen, manually choose reboot or run:"
      echo "fastboot reboot"
    } 2>&1 | tee "${OUT_DIR}/03-fastboot/fastboot-skipped.txt"
  fi
else
  {
    echo
    echo "== adb dependent collection skipped =="
    date -Is
    echo
    echo "ADB was not authorized or no phone was detected."
    echo "Skipped live Treble, partition, DSU, and fastboot capture."
    echo "Kernel source and community checks will still run."
  } 2>&1 | tee "${OUT_DIR}/02-treble/adb-dependent-collection-skipped.txt"
fi

{
  echo
  echo "== official Xiaomi kernel source branch discovery =="
  date -Is
  echo
  echo "repo: https://github.com/MiCode/Xiaomi_Kernel_OpenSource"
  echo "expected branch: beryl-u-oss"
  echo

  git ls-remote --heads https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git \
    | grep -Ei 'beryl|citrine|mt6855|note.14|m7' || true
} 2>&1 | tee "${OUT_DIR}/04-kernel-source/xiaomi-kernel-branch-discovery.txt"

{
  echo
  echo "== clone or update official Xiaomi kernel source branch =="
  date -Is
  echo

  if [ -d "${KERNEL_DIR}/.git" ]; then
    echo "kernel source directory already exists, updating"
    git -C "${KERNEL_DIR}" fetch origin beryl-u-oss --depth 1 2>&1 || true
    git -C "${KERNEL_DIR}" checkout beryl-u-oss 2>&1 || true
    git -C "${KERNEL_DIR}" pull --ff-only origin beryl-u-oss 2>&1 || true
  else
    git clone \
      --depth 1 \
      --single-branch \
      --branch beryl-u-oss \
      https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git \
      "${KERNEL_DIR}" 2>&1 || true
  fi

  echo
  echo "== kernel source git status =="
  git -C "${KERNEL_DIR}" status --short 2>&1 || true
  git -C "${KERNEL_DIR}" rev-parse HEAD 2>&1 || true
  git -C "${KERNEL_DIR}" branch --show-current 2>&1 || true
} 2>&1 | tee "${OUT_DIR}/04-kernel-source/xiaomi-kernel-clone-update.txt"

{
  echo
  echo "== kernel source inventory =="
  date -Is
  echo

  if [ -d "${KERNEL_DIR}" ]; then
    echo "kernel_dir: ${KERNEL_DIR}"
    echo

    echo "== top-level inventory =="
    find "${KERNEL_DIR}" -maxdepth 2 \( -type f -o -type d \) 2>/dev/null \
      | sed "s#${KERNEL_DIR}#."# \
      | sort \
      | head -n 300

    echo
    echo "== key kernel files =="
    find "${KERNEL_DIR}" -maxdepth 6 -type f \
      \( -name 'Makefile' -o -name 'Kconfig' -o -name '*defconfig*' -o -name '*.dts' -o -name '*.dtsi' -o -name 'README*' -o -name 'build.config*' \) \
      2>/dev/null \
      | sed "s#${KERNEL_DIR}#."# \
      | sort \
      | head -n 500
  else
    echo "kernel source directory missing"
  fi
} 2>&1 | tee "${OUT_DIR}/04-kernel-source/kernel-source-inventory.txt"

{
  echo
  echo "== Lineage official device check =="
  date -Is
  echo

  for url in \
    "https://raw.githubusercontent.com/LineageOS/lineage_wiki/master/_data/devices/beryl.yml" \
    "https://raw.githubusercontent.com/LineageOS/lineage_wiki/master/_data/devices/citrine.yml"
  do
    echo "## ${url}"
    curl -L --fail --max-time 30 "${url}" 2>&1 | head -n 120 || true
    echo
  done
} 2>&1 | tee "${OUT_DIR}/05-community-checks/lineage-official-device-check.txt"

{
  echo
  echo "== AOSP GSI reference links =="
  date -Is
  echo
  echo "AOSP GSI documentation:"
  echo "https://source.android.com/docs/setup/build/gsi"
  echo
  echo "AOSP DSU documentation:"
  echo "https://source.android.com/docs/core/ota/dynamic-system-updates"
  echo
  echo "AOSP dynamic partitions:"
  echo "https://source.android.com/docs/core/ota/dynamic_partitions"
  echo
  echo "AOSP AVB:"
  echo "https://source.android.com/docs/security/features/verifiedboot/avb"
} 2>&1 | tee "${OUT_DIR}/05-community-checks/aosp-reference-links.txt"

{
  echo
  echo "== summary =="
  date -Is
  echo
  echo "adb_ready: ${ADB_READY}"
  echo "adb_serial: ${ADB_SERIAL}"
  echo "fastboot_ready: ${FASTBOOT_READY}"
  echo

  echo "device readiness indicators:"
  echo "- ADB reconnect evidence captured"
  echo "- Treble properties captured if ADB was ready"
  echo "- dynamic partition property captured if ADB was ready"
  echo "- virtual A/B property captured if ADB was ready"
  echo "- AVB and vbmeta state captured if ADB was ready"
  echo "- fastboot getvars captured if fastboot was ready"
  echo "- Xiaomi kernel source branch discovery captured"
  echo

  echo "kernel source:"
  if [ -d "${KERNEL_DIR}/.git" ]; then
    echo "present: ${KERNEL_DIR}"
    echo "branch: $(git -C "${KERNEL_DIR}" branch --show-current 2>/dev/null || true)"
    echo "commit: $(git -C "${KERNEL_DIR}" rev-parse HEAD 2>/dev/null || true)"
  else
    echo "not cloned"
  fi
  echo

  echo "safety:"
  echo "no flashing"
  echo "no bootloader unlock"
  echo "adb and fastboot read-only queries only"
  echo "kernel source cloned outside the project git repo"
} 2>&1 | tee "${OUT_DIR}/06-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
