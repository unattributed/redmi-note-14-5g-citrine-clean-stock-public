#!/usr/bin/env bash
set -u

EVIDENCE_ROOT="/home/foo/android-rom-dev-evidence"
RUN_ID="citrine-android-sdk-build-tools-setup-$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${EVIDENCE_ROOT}/${RUN_ID}"
PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
ANDROID_SDK_ROOT_DEFAULT="/home/foo/Android/Sdk"
ANDROID_SDK_ROOT_EFFECTIVE="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${ANDROID_SDK_ROOT_DEFAULT}}}"
TARGET_BUILD_TOOLS="36.0.0"
TARGET_PLATFORM="android-36"

mkdir -p "${OUT_DIR}"/{00-context,01-before,02-sdkmanager,03-after,04-summary}

log_section() {
  local title="$1"
  echo
  echo "== ${title} =="
  date -Is
  echo
}

find_first_executable() {
  local candidate
  for candidate in "$@"; do
    if [ -n "${candidate}" ] && [ -x "${candidate}" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

find_sdkmanager() {
  local from_path=""
  from_path="$(command -v sdkmanager 2>/dev/null || true)"
  find_first_executable \
    "${from_path}" \
    "${ANDROID_SDK_ROOT_EFFECTIVE}/cmdline-tools/latest/bin/sdkmanager" \
    "/home/foo/Android/Sdk/cmdline-tools/latest/bin/sdkmanager" \
    "/home/foo/Workspace/android-sdk/cmdline-tools/latest/bin/sdkmanager" \
    "/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager" \
    "/usr/lib/android-sdk/cmdline-tools/latest/bin/sdkmanager"
}

find_tool_path() {
  local tool_name="$1"
  local from_path=""
  from_path="$(command -v "${tool_name}" 2>/dev/null || true)"
  if [ -n "${from_path}" ] && [ -x "${from_path}" ]; then
    printf '%s\n' "${from_path}"
    return 0
  fi

  find "${ANDROID_SDK_ROOT_EFFECTIVE}" -type f -name "${tool_name}" -perm -111 2>/dev/null | sort -V | tail -n 1
}

{
  echo "android sdk build-tools setup"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "out_dir: ${OUT_DIR}"
  echo "project_dir: ${PROJECT_DIR}"
  echo "android_sdk_root_effective: ${ANDROID_SDK_ROOT_EFFECTIVE}"
  echo "target_build_tools: ${TARGET_BUILD_TOOLS}"
  echo "target_platform: ${TARGET_PLATFORM}"
} 2>&1 | tee "${OUT_DIR}/00-context/run-context.txt"

{
  log_section "host baseline"
  cat /etc/os-release 2>/dev/null || true
  echo
  uname -a
  echo
  df -h /home "${PROJECT_DIR}" "${EVIDENCE_ROOT}" 2>/dev/null || true
} 2>&1 | tee "${OUT_DIR}/00-context/host-baseline.txt"

{
  log_section "tool baseline before install"
  for tool in java javac unzip curl sdkmanager aapt2 aapt apkanalyzer; do
    printf '%-14s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  java -version 2>&1 || true
  echo
  echo "ANDROID_HOME=${ANDROID_HOME:-}"
  echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-}"
  echo "PATH=${PATH}"
} 2>&1 | tee "${OUT_DIR}/01-before/tool-baseline-before.txt"

SDKMANAGER="$(find_sdkmanager || true)"

{
  log_section "sdkmanager detection"
  if [ -n "${SDKMANAGER}" ]; then
    echo "sdkmanager: ${SDKMANAGER}"
    "${SDKMANAGER}" --version 2>&1 || true
  else
    echo "sdkmanager: missing"
    echo
    echo "No Android SDK sdkmanager was found."
    echo "Install Android SDK Command-Line Tools from the official Android Studio downloads page,"
    echo "place them under an Android SDK root such as /home/foo/Android/Sdk/cmdline-tools/latest,"
    echo "then rerun this script."
    echo
    echo "Official docs describe sdkmanager as part of the Android SDK Command-Line Tools package."
  fi
} 2>&1 | tee "${OUT_DIR}/02-sdkmanager/sdkmanager-detection.txt"

if [ -n "${SDKMANAGER}" ]; then
  {
    log_section "sdkmanager package install"
    echo "Installing Android SDK packages into: ${ANDROID_SDK_ROOT_EFFECTIVE}"
    echo "Packages: build-tools;${TARGET_BUILD_TOOLS} platforms;${TARGET_PLATFORM}"
    echo
    echo "If license prompts appear, review them and answer as appropriate."
    echo
    "${SDKMANAGER}" --sdk_root="${ANDROID_SDK_ROOT_EFFECTIVE}" \
      "build-tools;${TARGET_BUILD_TOOLS}" \
      "platforms;${TARGET_PLATFORM}"
  } 2>&1 | tee "${OUT_DIR}/02-sdkmanager/sdkmanager-install.txt"
else
  {
    log_section "sdkmanager install skipped"
    echo "Install skipped because sdkmanager is missing."
  } 2>&1 | tee "${OUT_DIR}/02-sdkmanager/sdkmanager-install-skipped.txt"
fi

{
  log_section "tool baseline after install"
  for tool in sdkmanager aapt2 aapt apkanalyzer; do
    printf '%-14s ' "${tool}:"
    command -v "${tool}" || true
  done
  echo
  echo "== SDK-local tool discovery =="
  for tool in aapt2 aapt apkanalyzer; do
    printf '%-14s ' "${tool}:"
    find_tool_path "${tool}" || true
  done
  echo
  echo "== build-tools directory =="
  find "${ANDROID_SDK_ROOT_EFFECTIVE}/build-tools" -maxdepth 2 -type f \( -name aapt2 -o -name aapt \) -print 2>/dev/null | sort -V || true
} 2>&1 | tee "${OUT_DIR}/03-after/tool-baseline-after.txt"

AAPT2_PATH="$(find_tool_path aapt2 || true)"
AAPT_PATH="$(find_tool_path aapt || true)"
APKANALYZER_PATH="$(find_tool_path apkanalyzer || true)"

{
  log_section "summary"
  echo "sdkmanager_found: $([ -n "${SDKMANAGER}" ] && echo yes || echo no)"
  echo "sdkmanager_path: ${SDKMANAGER}"
  echo "android_sdk_root_effective: ${ANDROID_SDK_ROOT_EFFECTIVE}"
  echo "aapt2_path: ${AAPT2_PATH}"
  echo "aapt_path: ${AAPT_PATH}"
  echo "apkanalyzer_path: ${APKANALYZER_PATH}"
  echo
  if [ -n "${AAPT2_PATH}" ] || [ -n "${AAPT_PATH}" ] || [ -n "${APKANALYZER_PATH}" ]; then
    echo "result: apk decode tooling is now available or partially available"
    echo "next_step: rerun scripts/step16-dynsystem-apk-official-tool-decode.sh"
  else
    echo "result: apk decode tooling is still missing"
    echo "next_step: install Android SDK Command-Line Tools and Build Tools, then rerun this script"
  fi
  echo
  echo "safety: host-side SDK setup only, no phone flashing, no DSU install, no bootloader unlock"
} 2>&1 | tee "${OUT_DIR}/04-summary/summary.txt"

cd "${EVIDENCE_ROOT}" || exit 1
tar -czf "${RUN_ID}.tar.gz" "${RUN_ID}"

echo
echo "upload this file if installation fails or produces unclear output:"
echo "${EVIDENCE_ROOT}/${RUN_ID}.tar.gz"
