#!/usr/bin/env bash
set -u

PROJECT_ROOT="/home/foo/Workspace/android-rom-dev"
OUT="$HOME/android-rom-dev-private-evidence/step43-adb-visible-launcher-inventory-$(date +%Y%m%d-%H%M%S)"
LOG="$OUT/step43-adb-visible-launcher-inventory.txt"

mkdir -p "$OUT"

adb_clean() {
  adb "$@" 2>&1 | tr -d '\r'
}

write_header() {
  printf '\n== %s ==\n' "$1" | tee -a "$LOG"
}

extract_launcher_packages() {
  grep -E 'packageName=' "$OUT/launcher-activities-raw.txt" \
    | sed -E 's/.*packageName=([^[:space:]]+).*/\1/' \
    | sort -u
}

is_oem_launcher_package() {
  grep -E '^(com\.miui\.|com\.xiaomi\.|com\.mi\.|com\.mipay\.|com\.duokan\.|com\.android\.thememanager$)'
}

cd "$PROJECT_ROOT" || exit 1

{
  echo "== timestamp =="
  date -Is
  echo

  echo "== repo state =="
  git status --short
  git log --oneline -5
  echo

  echo "== adb state =="
  adb_clean get-state
  echo

  echo "== boot completed =="
  adb_clean shell getprop sys.boot_completed
} | tee "$LOG"

write_header "enabled packages for user 0"
adb_clean shell pm list packages -e --user 0 | sort | tee "$OUT/enabled-packages-user0.txt" | tee -a "$LOG" >/dev/null

write_header "disabled packages for user 0"
adb_clean shell pm list packages -d --user 0 | sort | tee "$OUT/disabled-packages-user0.txt" | tee -a "$LOG" >/dev/null

write_header "third-party packages for user 0"
adb_clean shell pm list packages -3 --user 0 | sort | tee "$OUT/third-party-packages-user0.txt" | tee -a "$LOG" >/dev/null

write_header "launcher activities raw"
adb_clean shell cmd package query-activities \
  --user 0 \
  -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER \
  > "$OUT/launcher-activities-raw.txt"

sed -n '1,260p' "$OUT/launcher-activities-raw.txt" | tee -a "$LOG"

extract_launcher_packages > "$OUT/launcher-packages-user0.txt"

write_header "launcher-visible packages, package only"
cat "$OUT/launcher-packages-user0.txt" | tee -a "$LOG"

write_header "launcher-visible OEM-looking packages"
is_oem_launcher_package < "$OUT/launcher-packages-user0.txt" \
  | tee "$OUT/launcher-oem-looking-packages-user0.txt" \
  | tee -a "$LOG" || true

write_header "known removed or disabled cleanup targets"
for pkg in \
  com.miui.analytics \
  com.miui.msa.global \
  com.miui.thirdappassistant \
  com.miui.bugreport \
  com.xiaomi.mipicks \
  com.xiaomi.discover \
  com.miui.videoplayer \
  com.miui.yellowpage \
  com.mi.android.globalFileexplorer \
  com.mi.appfinder \
  com.mi.globalminusscreen \
  com.mi.healthglobal \
  com.miui.android.fashiongallery \
  com.miui.cleaner \
  com.miui.fm \
  com.miui.fmservice \
  com.miui.player \
  com.xiaomi.calendar \
  com.android.thememanager \
  com.miui.gallery \
  com.miui.miservice \
  com.xiaomi.glgm \
  com.miui.calculator \
  com.miui.compass \
  com.miui.notes \
  com.xiaomi.scanner
do
  present="no"
  enabled="no"
  disabled="no"
  launcher="no"

  adb_clean shell pm list packages --user 0 "$pkg" | grep -Fxq "package:$pkg" && present="yes"
  adb_clean shell pm list packages -e --user 0 "$pkg" | grep -Fxq "package:$pkg" && enabled="yes"
  adb_clean shell pm list packages -d --user 0 "$pkg" | grep -Fxq "package:$pkg" && disabled="yes"
  grep -Fxq "$pkg" "$OUT/launcher-packages-user0.txt" && launcher="yes"

  printf '%-45s present_user0=%-3s enabled_user0=%-3s disabled_user0=%-3s launcher_visible=%s\n' \
    "$pkg" "$present" "$enabled" "$disabled" "$launcher"
done | tee "$OUT/cleanup-target-state.tsv" | tee -a "$LOG"

write_header "remaining enabled xiaomi or miui packages"
grep -E 'package:(com\.miui\.|com\.xiaomi\.|com\.mi\.|com\.mipay\.|com\.duokan\.)' \
  "$OUT/enabled-packages-user0.txt" \
  | sort \
  | tee "$OUT/remaining-enabled-oem-packages-user0.txt" \
  | tee -a "$LOG" || true

write_header "summary"
{
  echo "evidence_directory: $OUT"
  echo "launcher_package_count: $(wc -l < "$OUT/launcher-packages-user0.txt")"
  echo "launcher_oem_looking_count: $(wc -l < "$OUT/launcher-oem-looking-packages-user0.txt" 2>/dev/null || echo 0)"
  echo "disabled_cleanup_target_count: $(grep -c 'disabled_user0=yes' "$OUT/cleanup-target-state.tsv" || true)"
  echo "launcher_visible_cleanup_target_count: $(grep -c 'launcher_visible=yes' "$OUT/cleanup-target-state.tsv" || true)"
} | tee "$OUT/summary.txt" | tee -a "$LOG"

echo
echo "== evidence directory =="
echo "$OUT"
