#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="/home/foo/Workspace/android-rom-dev"
BACKUP_ROOT="/home/foo/android-rom-dev-private-backups"
RUN_ID="redmi-note-14-5g-citrine-media-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${RUN_ID}"
LOG_FILE="${BACKUP_DIR}/backup-session-log.txt"
REMOTE_ROOT="/storage/emulated/0"

mkdir -p "${BACKUP_DIR}"

log() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE}"
}

run_logged() {
  log ""
  log "== $* =="
  "$@" 2>&1 | tee -a "${LOG_FILE}"
}

adb_shell() {
  adb shell "$@" 2>&1 | tee -a "${LOG_FILE}"
}

remote_exists() {
  local remote_path="$1"
  adb shell "[ -e \"${remote_path}\" ]" >/dev/null 2>&1
}

pull_if_present() {
  local relative_path="$1"
  local remote_path="${REMOTE_ROOT}/${relative_path}"
  local local_parent

  log ""
  log "== backup candidate: ${relative_path} =="

  if remote_exists "${remote_path}"; then
    local_parent="$(dirname "${BACKUP_DIR}/${relative_path}")"
    mkdir -p "${local_parent}"
    log "remote present: ${remote_path}"
    log "local target: ${BACKUP_DIR}/${relative_path}"
    adb pull "${remote_path}" "${BACKUP_DIR}/${relative_path}" 2>&1 | tee -a "${LOG_FILE}"
  else
    log "remote missing, skipped: ${remote_path}"
  fi
}

{
  echo "redmi note 14 5g citrine media backup"
  echo "timestamp: $(date -Is)"
  echo "hostname: $(hostname)"
  echo "user: $(whoami)"
  echo "project_dir: ${PROJECT_DIR}"
  echo "backup_dir: ${BACKUP_DIR}"
  echo
  echo "safety:"
  echo "- no bootloader unlock"
  echo "- no flashing"
  echo "- no userdata erase"
  echo "- no DSU install"
  echo "- shared storage pull only"
  echo
} | tee "${LOG_FILE}"

log "== adb devices =="
adb devices -l 2>&1 | tee -a "${LOG_FILE}"

log ""
log "== user and storage state =="
adb shell 'cmd user list 2>&1 || true' 2>&1 | tee -a "${LOG_FILE}"
adb shell 'dumpsys user 2>/dev/null | grep -Ei "UserInfo|RUNNING_UNLOCKED|Started users state" | head -n 80 || true' 2>&1 | tee -a "${LOG_FILE}"
adb shell 'ls -lad /sdcard /storage/self/primary /storage/emulated/0 2>&1 || true' 2>&1 | tee -a "${LOG_FILE}"
adb shell 'ls -la /storage/emulated/0 2>&1 | head -n 80 || true' 2>&1 | tee -a "${LOG_FILE}"

if ! adb shell '[ -d /storage/emulated/0/DCIM ]' >/dev/null 2>&1; then
  log ""
  log "ERROR: shared storage is not visible. Unlock the phone screen, wait 30 seconds, then rerun this script."
  log "No backup completed."
  exit 2
fi

log ""
log "== remote size estimate =="
adb shell '
for p in \
  /storage/emulated/0/DCIM \
  /storage/emulated/0/Pictures \
  /storage/emulated/0/Movies \
  /storage/emulated/0/Download \
  /storage/emulated/0/Documents \
  /storage/emulated/0/Music \
  /storage/emulated/0/Recordings \
  /storage/emulated/0/Android/media/com.whatsapp \
  /storage/emulated/0/Android/media/com.whatsapp.w4b \
  /storage/emulated/0/Android/media/org.telegram.messenger \
  /storage/emulated/0/MIUI/backup
do
  if [ -e "$p" ]; then
    du -sh "$p" 2>/dev/null || echo "size unavailable: $p"
  else
    echo "missing: $p"
  fi
done
' 2>&1 | tee -a "${LOG_FILE}"

pull_if_present "DCIM"
pull_if_present "Pictures"
pull_if_present "Movies"
pull_if_present "Download"
pull_if_present "Documents"
pull_if_present "Music"
pull_if_present "Recordings"
pull_if_present "Notifications"
pull_if_present "Ringtones"
pull_if_present "MIUI/backup"
pull_if_present "Android/media/com.whatsapp"
pull_if_present "Android/media/com.whatsapp.w4b"
pull_if_present "Android/media/org.telegram.messenger"

log ""
log "== local backup inventory =="
{
  echo "backup_dir=${BACKUP_DIR}"
  echo "timestamp=$(date -Is)"
  echo "file_count=$(find "${BACKUP_DIR}" -type f | wc -l)"
  echo "directory_count=$(find "${BACKUP_DIR}" -type d | wc -l)"
  echo "backup_size=$(du -sh "${BACKUP_DIR}" | awk '{print $1}')"
  echo
  echo "top_level_sizes:"
  du -sh "${BACKUP_DIR}"/* 2>/dev/null | sort -h || true
} | tee "${BACKUP_DIR}/backup-inventory.txt" | tee -a "${LOG_FILE}"

log ""
log "== completion =="
log "backup completed at: $(date -Is)"
log "backup directory: ${BACKUP_DIR}"
log "inventory file: ${BACKUP_DIR}/backup-inventory.txt"
log ""
log "Do not commit this backup directory to Git."

exit 0
