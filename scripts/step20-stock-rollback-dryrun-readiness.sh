#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-stock-rollback-dryrun-readiness-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
FIRMWARE_ROOT="${PROJECT_DIR}/firmware/citrine-official"

mkdir -p "${OUT_DIR}"/{00-context,01-firmware,02-flash-scripts,03-images,04-fastboot,05-summary}

log_file() {
  local file="$1"
  shift
  {
    echo "== $* =="
    date -Is
    echo
  } > "${file}"
}

append_section() {
  local file="$1"
  shift
  {
    echo
    echo "== $* =="
    date -Is
    echo
  } >> "${file}"
}

record_context() {
  local file="${OUT_DIR}/00-context/run-context.txt"
  log_file "${file}" "run context"
  {
    echo "run_id: ${RUN_ID}"
    echo "timestamp: $(date -Is)"
    echo "hostname: $(hostname)"
    echo "user: $(whoami)"
    echo "project_dir: ${PROJECT_DIR}"
    echo "firmware_root: ${FIRMWARE_ROOT}"
    echo "out_dir: ${OUT_DIR}"
    echo
    echo "safety boundary:"
    echo "- no bootloader unlock"
    echo "- no flashing"
    echo "- no userdata erase"
    echo "- no Xiaomi flash script execution"
    echo "- no DSU or GSI install"
    echo "- read-only firmware and fastboot inspection only"
  } >> "${file}"
}

record_host_tools() {
  local file="${OUT_DIR}/00-context/host-tools.txt"
  log_file "${file}" "host tools"
  {
    cat /etc/os-release 2>/dev/null || true
    echo
    uname -a
    echo
    for tool in adb fastboot sha256sum tar find awk sed grep file stat bash; do
      printf '%-12s ' "${tool}:"
      command -v "${tool}" || true
    done
    echo
    adb version 2>&1 || true
    fastboot --version 2>&1 || true
  } >> "${file}"
}

find_firmware_tree() {
  find "${FIRMWARE_ROOT}/extracted/stage1" -maxdepth 2 -type d -name images 2>/dev/null | sort | tail -n 1 | sed 's#/images$##'
}

record_firmware_package() {
  local file="${OUT_DIR}/01-firmware/firmware-package-and-checksums.txt"
  log_file "${file}" "firmware package and checksums"
  {
    echo "== firmware root =="
    ls -la "${FIRMWARE_ROOT}" 2>&1 || true
    echo
    echo "== downloads =="
    ls -lh "${FIRMWARE_ROOT}/downloads" 2>&1 || true
    echo
    echo "== recorded checksums =="
    cat "${FIRMWARE_ROOT}/checksums/sha256sums.txt" 2>&1 || true
    echo
    echo "== recomputed downloaded package hashes =="
    find "${FIRMWARE_ROOT}/downloads" -maxdepth 1 -type f \( -name '*.tgz' -o -name '*.tar.gz' -o -name '*.zip' \) -print0 2>/dev/null | while IFS= read -r -d '' pkg; do
      sha256sum "${pkg}" 2>&1 || true
      file "${pkg}" 2>&1 || true
      ls -lh "${pkg}" 2>&1 || true
      echo
    done
  } >> "${file}"
}

record_firmware_tree() {
  local tree="$1"
  local file="${OUT_DIR}/01-firmware/extracted-firmware-tree.txt"
  log_file "${file}" "extracted firmware tree"
  {
    echo "selected_firmware_tree: ${tree}"
    echo
    if [ -n "${tree}" ] && [ -d "${tree}" ]; then
      echo "== top level =="
      ls -la "${tree}" 2>&1 || true
      echo
      echo "== images directory =="
      ls -lh "${tree}/images" 2>&1 || true
      echo
      echo "== shallow file list =="
      find "${tree}" -maxdepth 2 -type f | sort 2>&1 || true
    else
      echo "ERROR: no extracted firmware tree with images directory was found."
    fi
  } >> "${file}"
}

record_flash_scripts() {
  local tree="$1"
  local file="${OUT_DIR}/02-flash-scripts/flash-script-review.txt"
  log_file "${file}" "flash script review, not executed"
  {
    echo "selected_firmware_tree: ${tree}"
    echo
    if [ -z "${tree}" ] || [ ! -d "${tree}" ]; then
      echo "ERROR: no firmware tree available."
      return 0
    fi

    echo "== flash script candidates =="
    find "${tree}" -maxdepth 2 -type f \( -iname 'flash*.sh' -o -iname '*.bat' \) -print | sort 2>&1 || true
    echo

    find "${tree}" -maxdepth 2 -type f -iname 'flash*.sh' -print0 | sort -z | while IFS= read -r -d '' script; do
      echo "## ${script}"
      ls -l "${script}" 2>&1 || true
      echo
      echo "bash syntax check only, not execution:"
      bash -n "${script}" 2>&1 || true
      echo
      echo "commands of interest:"
      grep -nEi 'fastboot|flash|erase|format|set_active|reboot|lock|unlock|userdata|super|vbmeta|vendor_boot|boot|dtbo|init_boot|md1img' "${script}" 2>&1 || true
      echo
    done

    echo "== warning =="
    echo "No flash script was executed by this collector."
  } >> "${file}"
}

record_image_inventory() {
  local tree="$1"
  local file="${OUT_DIR}/03-images/image-inventory.txt"
  log_file "${file}" "image inventory"
  {
    echo "selected_firmware_tree: ${tree}"
    echo
    if [ -z "${tree}" ] || [ ! -d "${tree}/images" ]; then
      echo "ERROR: no images directory available."
      return 0
    fi

    echo "== selected image files, size and type =="
    for img in boot.img vendor_boot.img init_boot.img dtbo.img vbmeta.img vbmeta_system.img vbmeta_vendor.img super.img md1img.img lk.img; do
      p="${tree}/images/${img}"
      echo "## ${img}"
      if [ -f "${p}" ]; then
        ls -lh "${p}" 2>&1 || true
        file "${p}" 2>&1 || true
        sha256sum "${p}" 2>&1 || true
      else
        echo "missing"
      fi
      echo
    done

    echo "== all image files summary =="
    find "${tree}/images" -maxdepth 1 -type f -printf '%f\t%s bytes\n' | sort 2>&1 || true
  } >> "${file}"
}

wait_for_adb() {
  local attempts=24
  local n
  for n in $(seq 1 "${attempts}"); do
    adb devices 2>/dev/null | awk '$2 == "device" {found=1} END {exit found ? 0 : 1}' && return 0
    sleep 3
  done
  return 1
}

wait_for_fastboot() {
  local attempts=30
  local n
  for n in $(seq 1 "${attempts}"); do
    fastboot devices 2>/dev/null | awk 'NF >= 1 {found=1} END {exit found ? 0 : 1}' && return 0
    sleep 3
  done
  return 1
}

record_fastboot_state() {
  local file="${OUT_DIR}/04-fastboot/fastboot-readonly-state.txt"
  local adb_ready="no"
  local fastboot_ready="no"

  log_file "${file}" "fastboot read-only state"
  {
    echo "safety: read-only getvar capture only"
    echo
    echo "== adb devices before reboot =="
    adb devices -l 2>&1 || true
  } >> "${file}"

  if wait_for_adb; then
    adb_ready="yes"
    append_section "${file}" "rebooting to bootloader for read-only fastboot capture"
    adb reboot bootloader 2>&1 | tee -a "${file}" >/dev/null || true
    sleep 5
  else
    append_section "${file}" "adb not ready"
    echo "ADB was not ready, fastboot capture was skipped." >> "${file}"
  fi

  if [ "${adb_ready}" = "yes" ] && wait_for_fastboot; then
    fastboot_ready="yes"
    append_section "${file}" "fastboot getvar selected values"
    {
      echo "fastboot_ready: yes"
      echo
      fastboot devices 2>&1 || true
      echo
      for var in product current-slot slot-count unlocked secure anti version-bootloader version-baseband is-userspace max-download-size allow-wipe-userdata; do
        echo "## ${var}"
        fastboot getvar "${var}" 2>&1 || true
        echo
      done
    } >> "${file}"
    fastboot reboot 2>&1 | tee -a "${file}" >/dev/null || true
  else
    append_section "${file}" "fastboot not ready"
    echo "fastboot_ready: no" >> "${file}"
  fi

  {
    echo "adb_ready=${adb_ready}"
    echo "fastboot_ready=${fastboot_ready}"
  } > "${OUT_DIR}/04-fastboot/state.env"
}

record_summary() {
  local tree="$1"
  local file="${OUT_DIR}/05-summary/summary.txt"
  local adb_ready="unknown"
  local fastboot_ready="unknown"

  if [ -f "${OUT_DIR}/04-fastboot/state.env" ]; then
    # shellcheck disable=SC1091
    . "${OUT_DIR}/04-fastboot/state.env"
  fi

  log_file "${file}" "summary"
  {
    echo "selected_firmware_tree: ${tree}"
    echo "adb_ready: ${adb_ready}"
    echo "fastboot_ready: ${fastboot_ready}"
    echo
    echo "rollback proof status: partial, not end-to-end proven"
    echo
    echo "what this run can prove:"
    echo "- local stock firmware package and checksum records exist"
    echo "- extracted fastboot ROM anatomy can be inspected"
    echo "- flash scripts can be syntax-checked without execution"
    echo "- required image files can be inventoried"
    echo "- current device fastboot state can be captured read-only"
    echo
    echo "what this run cannot prove:"
    echo "- successful full factory reflash"
    echo "- recovery from hard brick"
    echo "- recovery if fastboot is unavailable"
    echo "- MediaTek authenticated service-tool recovery"
    echo "- safe relock after modifications"
    echo
    echo "safety result:"
    echo "- no unlock"
    echo "- no flashing"
    echo "- no userdata erase"
    echo "- no Xiaomi flash script execution"
    echo "- no DSU or GSI install"
  } >> "${file}"
}

main() {
  mkdir -p "${EVIDENCE_ROOT}"
  local firmware_tree
  firmware_tree="$(find_firmware_tree)"

  record_context
  record_host_tools
  record_firmware_package
  record_firmware_tree "${firmware_tree}"
  record_flash_scripts "${firmware_tree}"
  record_image_inventory "${firmware_tree}"
  record_fastboot_state
  record_summary "${firmware_tree}"

  cd "${EVIDENCE_ROOT}" || exit 1
  tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

  echo
  echo "stock rollback dry-run readiness evidence complete"
  echo "evidence bundle: ${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
  echo
  cat "${OUT_DIR}/05-summary/summary.txt"
}

main "$@"
