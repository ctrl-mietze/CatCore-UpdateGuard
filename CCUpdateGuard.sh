#!/data/data/com.termux/files/usr/bin/bash
# CatCore UpdateGuard - Android update control toolkit for Termux
# Backends: Root (su), ADB, Shizuku (rish)
# Scope: user/package/component level only. Does NOT modify /system, /vendor, boot, vbmeta, etc.
# Tested design target: Android 14-16 / One UI / AOSP-style devices.

set -u

APP="CatCore UpdateGuard"
VER="1.0.0"
STATE_HOME="$HOME/.catcore-updateguard"
mkdir -p "$STATE_HOME"

# ---------- Colors ----------
if [ -t 1 ]; then
  R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; M='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; D='\033[2m'; N='\033[0m'
else
  R=''; G=''; Y=''; B=''; M=''; C=''; W=''; D=''; N=''
fi

# ---------- Locale ----------
detect_lang() {
  local loc
  loc="$(getprop persist.sys.locale 2>/dev/null || true)"
  [ -z "$loc" ] && loc="$(getprop ro.product.locale 2>/dev/null || true)"
  [ -z "$loc" ] && loc="${LANG:-en_US}"
  case "$loc" in
    de*|DE*) LANG_CODE="de" ;;
    zh*|ZH*) LANG_CODE="zh" ;;
    *)       LANG_CODE="en" ;;
  esac
}

set_texts() {
  case "$LANG_CODE" in
    de)
      TXT_TITLE="Android Update Control Toolkit"
      TXT_CHOOSE_ACCESS="Zugriffsvariante wählen"
      TXT_ROOT="Root / su"
      TXT_ADB="ADB (Termux android-tools / Wireless ADB)"
      TXT_SHIZUKU="Shizuku / rish"
      TXT_AUTO="Automatisch erkennen"
      TXT_BACK="Zurück"
      TXT_INVALID="Ungültige Eingabe."
      TXT_PRESS="Enter zum Fortfahren..."
      TXT_BACKEND_OK="Backend aktiv"
      TXT_BACKEND_FAIL="Backend konnte nicht verwendet werden."
      TXT_MAIN="Hauptmenü"
      TXT_GP="Google Protector"
      TXT_GP_DESC="Pausiert Play Store und Google-Systemupdate-Clients userseitig"
      TXT_SYS="Disable System Updates"
      TXT_SYS_DESC="Herstellerprofil oder intelligente Updater-Suche"
      TXT_HARD="HARD PROTECTOR"
      TXT_HARD_DESC="Aggressiver Schutz gegen Store / OTA / Update-Clients"
      TXT_REVSEL="Reverse Select"
      TXT_REVA="Reverse all + Fast Fix"
      TXT_REVH="Reverse + Hard Broken Checker"
      TXT_CHECK="Check Broken only"
      TXT_AUDIT="Status / Audit"
      TXT_REPORT="Report nach Downloads exportieren"
      TXT_EXIT="Beenden"
      TXT_WARN_HARD="HARD PROTECTOR kann Play Store, OTA-Clients und optional Paketinstaller deaktivieren."
      TXT_CONFIRM="Zur Bestätigung exakt YES eingeben"
      TXT_MODEL="Geräteprofil wählen"
      TXT_STOCK="Stock Android / AOSP"
      TXT_SAMSUNG="Samsung / One UI"
      TXT_PIXEL="Google Pixel"
      TXT_NOTHING="Nothing OS"
      TXT_FIND="Try Finding / Updater automatisch suchen"
      TXT_FOUND="Gefundene Updater-Kandidaten"
      TXT_SELECT="Nummern wählen (z.B. 1 3 4) oder 0 für Abbruch"
      TXT_NONE="Keine passenden Pakete gefunden."
      TXT_DISABLED="Deaktiviert"
      TXT_ALREADY="Bereits deaktiviert"
      TXT_FAILED="Fehlgeschlagen"
      TXT_RESTORED="Wiederhergestellt"
      TXT_NO_STATE="Keine von CatCore UpdateGuard gespeicherten Änderungen vorhanden."
      TXT_INSTALL_LOCK="Auch Paketinstaller blockieren? Das verhindert normale APK-Installationen."
      TXT_YN="y/N"
      TXT_SAFE="Kernkomponenten werden durch Never-Touch-Regeln geschützt."
      TXT_REPORT_SAVED="Report gespeichert"
      TXT_STORAGE="Downloads nicht verfügbar; nutze lokalen Ordner"
      TXT_DEVICE="Gerät"
      TXT_ANDROID="Android"
      TXT_PATCH="Security Patch"
      TXT_FP="Fingerprint"
      TXT_ACCESS="Zugriff"
      TXT_CHECKING="Prüfe Systemzustand..."
      TXT_BROKEN="Mögliche Probleme gefunden"
      TXT_OK="Keine offensichtlichen kritischen Probleme gefunden"
      TXT_FIX="Fast Fix versucht"
      TXT_COMPONENTS="Pixel/AOSP: Update-Komponenten innerhalb Google Play Services suchen"
      TXT_GOOGLE_NOTE="Hinweis: Google Protector friert den Play Store ein. Mit Reverse wird er wieder aktiviert."
      TXT_MAINLINE_NOTE="Google Play-Systemupdates sind Mainline/APEX; CatCore UpdateGuard blockiert nur steuernde User-/App-Komponenten, nicht /system/APEX-Dateien."
      TXT_SCOPE="Nur Paket-/Komponentenebene • keine Änderung an Systempartition, Boot oder vbmeta"
      TXT_PROTECTION="SCHUTZ"
      TXT_RECOVERY="WIEDERHERSTELLUNG & PRÜFUNG"
      TXT_TOOLS="STATUS & WERKZEUGE"
      TXT_ROOT_REMOVE="User Update Service Remover [DANGEROUS]"
      TXT_ROOT_REMOVE_DESC="Root-only: entfernt gewählte System-Updater nur aus dem aktuellen Benutzerprofil"
      TXT_ROOT_ONLY="Diese Funktion ist ausschließlich mit aktivem Root verfügbar."
      TXT_DANGER_HEAD="GEFÄHRLICHER BEREICH"
      TXT_DANGER_STEP1="Zum Entsperren exakt Y eingeben"
      TXT_DANGER_STEP2="Zur endgültigen Bestätigung exakt BESTÄTIGEN eingeben"
      TXT_DANGER_TOKEN="BESTÄTIGEN"
      TXT_DANGER_WARNING="WARNUNG: Update-Dienste werden für das aktuelle Benutzerprofil deinstalliert. Falsche Auswahl kann Updates, Sicherheit und Stabilität beeinträchtigen. Du handelst eigenverantwortlich; es wird keinerlei Haftung übernommen. Nutze dies nur, wenn du genau weißt, was du tust."
      TXT_DANGER_ACK="Drücke Enter, wenn du die Warnung gelesen und verstanden hast..."
      TXT_SYSTEM_CANDIDATES="System-Updater-Kandidaten im aktuellen Benutzerprofil"
      TXT_BACKUP_SAVED="APK-Backup und Paketliste gespeichert unter"
      TXT_BACKUP_FAILED="Backup fehlgeschlagen – Paket wird NICHT entfernt"
      TXT_REMOVED_USER="Für Benutzerprofil deinstalliert"
      TXT_REINSTALLED_USER="Für Benutzerprofil wieder installiert"
      TXT_REINSTALL_FAILED="Wiederinstallation fehlgeschlagen"
      ;;
    zh)
      TXT_TITLE="Android 更新控制工具"
      TXT_CHOOSE_ACCESS="选择访问方式"
      TXT_ROOT="Root / su"
      TXT_ADB="ADB（Termux android-tools / 无线 ADB）"
      TXT_SHIZUKU="Shizuku / rish"
      TXT_AUTO="自动检测"
      TXT_BACK="返回"
      TXT_INVALID="输入无效。"
      TXT_PRESS="按 Enter 继续..."
      TXT_BACKEND_OK="后端已启用"
      TXT_BACKEND_FAIL="无法使用该后端。"
      TXT_MAIN="主菜单"
      TXT_GP="Google Protector"
      TXT_GP_DESC="在用户层暂停 Play 商店和 Google 系统更新客户端"
      TXT_SYS="Disable System Updates"
      TXT_SYS_DESC="厂商配置或智能更新器搜索"
      TXT_HARD="HARD PROTECTOR"
      TXT_HARD_DESC="更强的商店 / OTA / 更新客户端保护"
      TXT_REVSEL="Reverse Select"
      TXT_REVA="Reverse all + Fast Fix"
      TXT_REVH="Reverse + Hard Broken Checker"
      TXT_CHECK="Check Broken only"
      TXT_AUDIT="状态 / 审计"
      TXT_REPORT="导出报告到 Downloads"
      TXT_EXIT="退出"
      TXT_WARN_HARD="HARD PROTECTOR 可能禁用 Play 商店、OTA 客户端，并可选禁用安装器。"
      TXT_CONFIRM="请输入 YES 确认"
      TXT_MODEL="选择设备类型"
      TXT_STOCK="Stock Android / AOSP"
      TXT_SAMSUNG="Samsung / One UI"
      TXT_PIXEL="Google Pixel"
      TXT_NOTHING="Nothing OS"
      TXT_FIND="Try Finding / 自动搜索更新器"
      TXT_FOUND="找到的更新器候选"
      TXT_SELECT="选择编号（例如 1 3 4），0 取消"
      TXT_NONE="未找到匹配的软件包。"
      TXT_DISABLED="已禁用"
      TXT_ALREADY="已经禁用"
      TXT_FAILED="失败"
      TXT_RESTORED="已恢复"
      TXT_NO_STATE="CatCore UpdateGuard 未保存任何更改。"
      TXT_INSTALL_LOCK="也禁用软件包安装器？这会阻止正常 APK 安装。"
      TXT_YN="y/N"
      TXT_SAFE="Never-Touch 规则会保护核心系统组件。"
      TXT_REPORT_SAVED="报告已保存"
      TXT_STORAGE="Downloads 不可用；使用本地目录"
      TXT_DEVICE="设备"
      TXT_ANDROID="Android"
      TXT_PATCH="安全补丁"
      TXT_FP="指纹"
      TXT_ACCESS="访问方式"
      TXT_CHECKING="正在检查系统状态..."
      TXT_BROKEN="发现可能的问题"
      TXT_OK="未发现明显的关键问题"
      TXT_FIX="已尝试快速修复"
      TXT_COMPONENTS="Pixel/AOSP：在 Google Play Services 中搜索系统更新组件"
      TXT_GOOGLE_NOTE="注意：Google Protector 会冻结 Play 商店。Reverse 可恢复。"
      TXT_MAINLINE_NOTE="Google Play 系统更新属于 Mainline/APEX；CatCore UpdateGuard 只阻止用户层/应用层控制组件，不修改 /system 或 APEX 文件。"
      TXT_SCOPE="仅软件包/组件层面 • 不修改系统分区、Boot 或 vbmeta"
      TXT_PROTECTION="保护"
      TXT_RECOVERY="恢复与检查"
      TXT_TOOLS="状态与工具"
      TXT_ROOT_REMOVE="用户更新服务移除器 [危险]"
      TXT_ROOT_REMOVE_DESC="仅 Root：只从当前用户配置中移除所选系统更新程序"
      TXT_ROOT_ONLY="此功能仅在 Root 模式下可用。"
      TXT_DANGER_HEAD="危险区域"
      TXT_DANGER_STEP1="请输入大写 Y 解锁"
      TXT_DANGER_STEP2="请输入“我接受”进行最终确认"
      TXT_DANGER_TOKEN="我接受"
      TXT_DANGER_WARNING="警告：更新服务将从当前用户配置中卸载。错误选择可能影响更新、安全性和系统稳定性。所有操作风险由你自行承担，作者不承担任何责任。只有在你完全清楚自己操作的情况下才可继续。"
      TXT_DANGER_ACK="确认你已阅读并理解警告后，按 Enter 继续..."
      TXT_SYSTEM_CANDIDATES="当前用户配置中的系统更新程序候选"
      TXT_BACKUP_SAVED="APK 备份和软件包列表已保存到"
      TXT_BACKUP_FAILED="备份失败——不会移除该软件包"
      TXT_REMOVED_USER="已从用户配置中卸载"
      TXT_REINSTALLED_USER="已为用户配置重新安装"
      TXT_REINSTALL_FAILED="重新安装失败"
      ;;
    *)
      TXT_TITLE="Android Update Control Toolkit"
      TXT_CHOOSE_ACCESS="Choose access method"
      TXT_ROOT="Root / su"
      TXT_ADB="ADB (Termux android-tools / Wireless ADB)"
      TXT_SHIZUKU="Shizuku / rish"
      TXT_AUTO="Auto detect"
      TXT_BACK="Back"
      TXT_INVALID="Invalid input."
      TXT_PRESS="Press Enter to continue..."
      TXT_BACKEND_OK="Backend active"
      TXT_BACKEND_FAIL="Backend could not be used."
      TXT_MAIN="Main menu"
      TXT_GP="Google Protector"
      TXT_GP_DESC="Pauses Play Store and Google system-update clients at user level"
      TXT_SYS="Disable System Updates"
      TXT_SYS_DESC="Vendor profile or smart updater discovery"
      TXT_HARD="HARD PROTECTOR"
      TXT_HARD_DESC="Aggressive Store / OTA / update-client protection"
      TXT_REVSEL="Reverse Select"
      TXT_REVA="Reverse all + Fast Fix"
      TXT_REVH="Reverse + Hard Broken Checker"
      TXT_CHECK="Check Broken only"
      TXT_AUDIT="Status / Audit"
      TXT_REPORT="Export report to Downloads"
      TXT_EXIT="Exit"
      TXT_WARN_HARD="HARD PROTECTOR may disable Play Store, OTA clients and optionally package installers."
      TXT_CONFIRM="Type YES exactly to confirm"
      TXT_MODEL="Choose device profile"
      TXT_STOCK="Stock Android / AOSP"
      TXT_SAMSUNG="Samsung / One UI"
      TXT_PIXEL="Google Pixel"
      TXT_NOTHING="Nothing OS"
      TXT_FIND="Try Finding / auto-discover updater"
      TXT_FOUND="Updater candidates found"
      TXT_SELECT="Choose numbers (e.g. 1 3 4), or 0 to cancel"
      TXT_NONE="No matching packages found."
      TXT_DISABLED="Disabled"
      TXT_ALREADY="Already disabled"
      TXT_FAILED="Failed"
      TXT_RESTORED="Restored"
      TXT_NO_STATE="No changes saved by CatCore UpdateGuard."
      TXT_INSTALL_LOCK="Block package installers too? This prevents normal APK installation."
      TXT_YN="y/N"
      TXT_SAFE="Core components are protected by Never-Touch rules."
      TXT_REPORT_SAVED="Report saved"
      TXT_STORAGE="Downloads unavailable; using local folder"
      TXT_DEVICE="Device"
      TXT_ANDROID="Android"
      TXT_PATCH="Security patch"
      TXT_FP="Fingerprint"
      TXT_ACCESS="Access"
      TXT_CHECKING="Checking system state..."
      TXT_BROKEN="Possible problems found"
      TXT_OK="No obvious critical problems found"
      TXT_FIX="Fast Fix attempted"
      TXT_COMPONENTS="Pixel/AOSP: search system-update components inside Google Play Services"
      TXT_GOOGLE_NOTE="Note: Google Protector freezes the Play Store. Reverse restores it."
      TXT_MAINLINE_NOTE="Google Play system updates use Mainline/APEX; CatCore UpdateGuard blocks controlling user/app components only and never edits /system or APEX files."
      TXT_SCOPE="Package/component level only • no system partition, boot or vbmeta changes"
      TXT_PROTECTION="PROTECTION"
      TXT_RECOVERY="RECOVERY & HEALTH"
      TXT_TOOLS="STATUS & TOOLS"
      TXT_ROOT_REMOVE="User Update Service Remover [DANGEROUS]"
      TXT_ROOT_REMOVE_DESC="Root-only: removes selected system updaters from the current user profile"
      TXT_ROOT_ONLY="This function is available only with active Root access."
      TXT_DANGER_HEAD="DANGEROUS AREA"
      TXT_DANGER_STEP1="Type uppercase Y to unlock"
      TXT_DANGER_STEP2="Type ACCEPT exactly for final confirmation"
      TXT_DANGER_TOKEN="ACCEPT"
      TXT_DANGER_WARNING="WARNING: Update services will be uninstalled for the current user profile. A wrong selection can affect updates, security and stability. You act at your own risk; no liability is accepted. Continue only if you fully understand what you are doing."
      TXT_DANGER_ACK="Press Enter after you have read and understood this warning..."
      TXT_SYSTEM_CANDIDATES="System updater candidates in the current user profile"
      TXT_BACKUP_SAVED="APK backup and package list saved to"
      TXT_BACKUP_FAILED="Backup failed – package will NOT be removed"
      TXT_REMOVED_USER="Uninstalled for user profile"
      TXT_REINSTALLED_USER="Reinstalled for user profile"
      TXT_REINSTALL_FAILED="Reinstallation failed"
      ;;
  esac
}

detect_lang
set_texts

# ---------- Storage / logs ----------
prepare_storage() {
  if [ ! -d "$HOME/storage/downloads" ] && command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage >/dev/null 2>&1 || true
    sleep 1
  fi
  if [ -d "$HOME/storage/downloads" ]; then
    OUTDIR="$HOME/storage/downloads/CatCore-UpdateGuard"
  else
    OUTDIR="$HOME/CatCore-UpdateGuard"
    echo -e "${Y}[!] $TXT_STORAGE${N}"
  fi
  mkdir -p "$OUTDIR"
  LOG="$OUTDIR/catcore-updateguard-$(date +%Y%m%d-%H%M%S).log"
  : > "$LOG"
}
prepare_storage

log() { printf '%b\n' "$*" | tee -a "$LOG"; }
pause() { printf '\n%s' "$TXT_PRESS"; read -r _; }
clear_s() { command -v clear >/dev/null 2>&1 && clear || printf '\033c'; }

banner() {
  clear_s
  echo -e "${M}╭──────────────────────────────────────────────────────────────╮${N}"
  echo -e "${M}│${N}  ${Y}CATCORE${N}  ${W}U P D A T E G U A R D${N}                    ${D}v$VER${N}  ${M}│${N}"
  echo -e "${M}├──────────────────────────────────────────────────────────────┤${N}"
  echo -e "${M}│${N}  ${C}ROOT${N}  •  ${B}ADB${N}  •  ${G}SHIZUKU${N}                                  ${M}│${N}"
  echo -e "${M}╰──────────────────────────────────────────────────────────────╯${N}"
  echo -e "${D}$TXT_TITLE${N}"
  echo -e "${D}$TXT_SCOPE${N}"
  echo
}

# ---------- Backend implementation ----------
BACKEND=""
ADB_SERIAL=""
RISH=""

root_exec() {
  su -c "$1"
}

adb_exec() {
  adb -s "$ADB_SERIAL" shell "$1"
}

shizuku_exec() {
  "$RISH" -c "$1"
}

x() {
  local cmd="$1"
  case "$BACKEND" in
    root) root_exec "$cmd" ;;
    adb) adb_exec "$cmd" ;;
    shizuku) shizuku_exec "$cmd" ;;
    *) return 127 ;;
  esac
}

find_rish() {
  local c
  for c in "$(command -v rish 2>/dev/null || true)" "$PREFIX/bin/rish" "$HOME/rish" "$HOME/.local/bin/rish" "$PREFIX/opt/rish/rish"; do
    [ -n "$c" ] && [ -x "$c" ] && { RISH="$c"; return 0; }
  done
  return 1
}

setup_root() {
  command -v su >/dev/null 2>&1 || return 1
  [ "$(su -c 'id -u' 2>/dev/null | tr -d '\r')" = "0" ] || return 1
  BACKEND="root"
  return 0
}

setup_adb() {
  command -v adb >/dev/null 2>&1 || return 1
  local arr=() s
  while IFS= read -r s; do [ -n "$s" ] && arr+=("$s"); done < <(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')
  [ ${#arr[@]} -gt 0 ] || return 1
  if [ ${#arr[@]} -eq 1 ]; then
    ADB_SERIAL="${arr[0]}"
  else
    echo "ADB devices:"
    local i=1
    for s in "${arr[@]}"; do echo "  $i) $s"; i=$((i+1)); done
    printf "> "; read -r i
    [[ "$i" =~ ^[0-9]+$ ]] || return 1
    [ "$i" -ge 1 ] && [ "$i" -le "${#arr[@]}" ] || return 1
    ADB_SERIAL="${arr[$((i-1))]}"
  fi
  BACKEND="adb"
  adb -s "$ADB_SERIAL" shell id >/dev/null 2>&1 || return 1
  return 0
}

setup_shizuku() {
  find_rish || return 1
  local who
  who="$($RISH -c 'id -u' 2>/dev/null | tr -d '\r')"
  [ -n "$who" ] || return 1
  BACKEND="shizuku"
  return 0
}

select_backend() {
  while :; do
    banner
    echo -e "${W}$TXT_CHOOSE_ACCESS${N}"
    echo "  1) $TXT_ROOT"
    echo "  2) $TXT_ADB"
    echo "  3) $TXT_SHIZUKU"
    echo "  4) $TXT_AUTO"
    echo "  0) $TXT_EXIT"
    printf "> "; read -r c
    case "$c" in
      1) setup_root && break || echo -e "${R}[!] $TXT_BACKEND_FAIL${N}" ;;
      2) setup_adb && break || { echo -e "${R}[!] $TXT_BACKEND_FAIL${N}"; echo "    pkg install android-tools"; } ;;
      3) setup_shizuku && break || { echo -e "${R}[!] $TXT_BACKEND_FAIL${N}"; echo "    Shizuku → Use Shizuku in terminal apps → rish"; } ;;
      4) setup_root || setup_shizuku || setup_adb || true; [ -n "$BACKEND" ] && break || echo -e "${R}[!] $TXT_BACKEND_FAIL${N}" ;;
      0) exit 0 ;;
      *) echo "$TXT_INVALID" ;;
    esac
    sleep 1.2
  done
  echo -e "${G}[✓] $TXT_BACKEND_OK: $BACKEND${N}"
  sleep .7
}

# ---------- Target identity / state ----------
prop() { x "getprop $1" 2>/dev/null | tr -d '\r'; }
mk_target_state() {
  local model fp slug
  model="$(prop ro.product.model)"
  fp="$(prop ro.build.fingerprint)"
  slug="${model:-device}-${fp:-unknown}"
  slug="$(printf '%s' "$slug" | tr '/ :|\\' '_____' | tr -cd 'A-Za-z0-9._-')"
  [ -z "$slug" ] && slug="unknown"
  TARGET_DIR="$STATE_HOME/$slug"
  STATE_FILE="$TARGET_DIR/changes.tsv"
  META_FILE="$TARGET_DIR/meta.txt"
  mkdir -p "$TARGET_DIR"
  {
    echo "backend=$BACKEND"
    echo "adb_serial=$ADB_SERIAL"
    echo "model=$model"
    echo "fingerprint=$fp"
    echo "created=$(date -Iseconds 2>/dev/null || date)"
  } > "$META_FILE"
  touch "$STATE_FILE"
}

# ---------- Safeguards ----------
NEVER_TOUCH='^(android|com\.android\.systemui|com\.android\.settings|com\.google\.android\.permission(controller)?|com\.google\.android\.permission|com\.google\.android\.gms)$'

is_never_touch() {
  local item="${1%%/*}"
  printf '%s\n' "$item" | grep -Eq "$NEVER_TOUCH"
}

pkg_exists() { x "pm path '$1'" >/dev/null 2>&1; }

pkg_disabled() {
  x "pm list packages -d --user 0" 2>/dev/null | tr -d '\r' | grep -Fxq "package:$1"
}

remember_pkg() {
  local p="$1" reason="$2"
  grep -Fq "pkg|$p|" "$STATE_FILE" 2>/dev/null && return 0
  if pkg_disabled "$p"; then
    echo "pkg|$p|disabled_before|$reason" >> "$STATE_FILE"
  else
    echo "pkg|$p|enabled_before|$reason" >> "$STATE_FILE"
  fi
}

remember_component() {
  local c="$1" reason="$2"
  grep -Fq "component|$c|" "$STATE_FILE" 2>/dev/null || echo "component|$c|default_before|$reason" >> "$STATE_FILE"
}

disable_pkg() {
  local p="$1" reason="${2:-manual}"
  if is_never_touch "$p"; then
    log "${Y}[SKIP] Never-Touch: $p${N}"
    return 2
  fi
  if ! pkg_exists "$p"; then
    log "${D}[-] not installed: $p${N}"
    return 3
  fi
  if pkg_disabled "$p"; then
    log "${Y}[=] $TXT_ALREADY: $p${N}"
    return 0
  fi
  remember_pkg "$p" "$reason"
  if x "pm disable-user --user 0 '$p'" >/dev/null 2>&1; then
    log "${G}[✓] $TXT_DISABLED: $p${N}"
  else
    log "${R}[x] $TXT_FAILED: $p${N}"
    return 1
  fi
}

disable_component() {
  local c="$1" reason="${2:-component}"
  local p="${c%%/*}"
  if is_never_touch "$p" && [ "$p" != "com.google.android.gms" ] && [ "$p" != "com.google.android.gsf" ]; then
    log "${Y}[SKIP] Never-Touch: $c${N}"
    return 2
  fi
  pkg_exists "$p" || return 3
  remember_component "$c" "$reason"
  if x "pm disable-user --user 0 '$c'" >/dev/null 2>&1 || x "pm disable '$c'" >/dev/null 2>&1; then
    log "${G}[✓] $TXT_DISABLED: $c${N}"
  else
    log "${R}[x] $TXT_FAILED: $c${N}"
    return 1
  fi
}

restore_item() {
  local kind="$1" item="$2" before="$3"
  case "$kind" in
    pkg)
      if [ "$before" = "enabled_before" ]; then
        x "pm enable --user 0 '$item'" >/dev/null 2>&1 || x "pm default-state --user 0 '$item'" >/dev/null 2>&1
        log "${G}[✓] $TXT_RESTORED: $item${N}"
      fi
      ;;
    component)
      x "pm default-state --user 0 '$item'" >/dev/null 2>&1 || x "pm enable '$item'" >/dev/null 2>&1
      log "${G}[✓] $TXT_RESTORED: $item${N}"
      ;;
    uninstalled)
      if x "cmd package install-existing --user '$before' '$item'" >/dev/null 2>&1 || x "pm install-existing --user '$before' '$item'" >/dev/null 2>&1; then
        x "pm enable --user '$before' '$item'" >/dev/null 2>&1 || true
        log "${G}[✓] $TXT_REINSTALLED_USER: $item (user $before)${N}"
      else
        log "${R}[x] $TXT_REINSTALL_FAILED: $item (user $before)${N}"
        return 1
      fi
      ;;
  esac
}

# ---------- Profiles ----------
google_protector() {
  banner
  echo -e "${C}$TXT_GP${N}"
  echo "$TXT_GOOGLE_NOTE"
  echo "$TXT_MAINLINE_NOTE"
  echo
  local pkgs=(
    com.android.vending
    com.google.android.modulemetadata
    com.android.modulemetadata
    com.google.android.configupdater
  )
  local p
  for p in "${pkgs[@]}"; do disable_pkg "$p" "google_protector" || true; done

  echo
  pause
}

samsung_profile() {
  local pkgs=(com.samsung.sdm com.wssyncmldm com.sec.android.soagent)
  local p found=0
  for p in "${pkgs[@]}"; do
    if pkg_exists "$p"; then found=1; disable_pkg "$p" "samsung_ota" || true; fi
  done
  [ "$found" -eq 0 ] && try_find_updaters
}

nothing_profile() {
  # Offline updater is known; online updater package varies by Nothing OS release.
  local found=0 p
  for p in com.nothing.OfflineOTAUpgradeApp com.nothing.systemupdate com.nothing.updater; do
    if pkg_exists "$p"; then found=1; disable_pkg "$p" "nothing_ota" || true; fi
  done
  # Always run discovery so newer Nothing package names can be selected.
  try_find_updaters
}

pixel_components() {
  echo -e "${C}$TXT_COMPONENTS${N}"
  local comps=(
    'com.google.android.gms/.update.SystemUpdateActivity'
    'com.google.android.gms/.update.SystemUpdateService'
    'com.google.android.gms/.update.SystemUpdateService$ActiveReceiver'
    'com.google.android.gms/.update.SystemUpdateService$Receiver'
    'com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver'
    'com.google.android.gsf/.update.SystemUpdateActivity'
    'com.google.android.gsf/.update.SystemUpdateService'
    'com.google.android.gsf/.update.SystemUpdateService$Receiver'
    'com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver'
  )
  local c
  for c in "${comps[@]}"; do disable_component "$c" "pixel_system_update" || true; done
}

aosp_profile() {
  pixel_components
  try_find_updaters
}

# Dynamic discovery: package-name based, intentionally requires user selection.
try_find_updaters() {
  echo
  echo -e "${C}[*] $TXT_FIND${N}"
  local all tmp
  tmp="$TARGET_DIR/candidates.txt"
  x "pm list packages --user 0" 2>/dev/null | tr -d '\r' | sed 's/^package://' > "$tmp.all"

  # Rank very likely candidates first, then broader 'system' names.
  {
    grep -Ei '(wssync|soagent|(^|\.)sdm$|update|updater|ota|fota|firmware|softwareupdate|systemupdate)' "$tmp.all" || true
    grep -Ei 'system' "$tmp.all" | grep -Evi '(systemui|systemwebview|filesystem|keystore|permission|settings)' || true
  } | awk '!seen[$0]++' > "$tmp"

  mapfile -t CANDS < "$tmp"
  if [ ${#CANDS[@]} -eq 0 ]; then
    echo -e "${Y}$TXT_NONE${N}"
    rm -f "$tmp.all" "$tmp"
    return 0
  fi

  echo -e "${W}$TXT_FOUND:${N}"
  local i=1 p score tag
  for p in "${CANDS[@]}"; do
    score="LOW"
    printf '%s' "$p" | grep -Eqi '(wssync|soagent|(^|\.)sdm$|systemupdate|softwareupdate|updater|fota|ota)' && score="HIGH"
    [ "$score" = "HIGH" ] && tag="${G}HIGH${N}" || tag="${Y}LOW${N}"
    printf " %2d) [%b] %s\n" "$i" "$tag" "$p"
    i=$((i+1))
  done
  echo
  echo "$TXT_SELECT"
  printf "> "; read -r picks
  [ "$picks" = "0" ] && { rm -f "$tmp.all" "$tmp"; return 0; }
  local n
  for n in $picks; do
    [[ "$n" =~ ^[0-9]+$ ]] || continue
    [ "$n" -ge 1 ] && [ "$n" -le "${#CANDS[@]}" ] || continue
    p="${CANDS[$((n-1))]}"
    disable_pkg "$p" "discovery_selected" || true
  done
  rm -f "$tmp.all" "$tmp"
}

disable_system_updates() {
  while :; do
    banner
    echo -e "${W}$TXT_MODEL${N}"
    echo "  1) $TXT_STOCK"
    echo "  2) $TXT_SAMSUNG"
    echo "  3) $TXT_PIXEL"
    echo "  4) $TXT_NOTHING"
    echo "  5) $TXT_FIND"
    echo "  0) $TXT_BACK"
    printf "> "; read -r c
    case "$c" in
      1) aosp_profile; break ;;
      2) samsung_profile; break ;;
      3) pixel_components; break ;;
      4) nothing_profile; break ;;
      5) try_find_updaters; break ;;
      0) return ;;
      *) echo "$TXT_INVALID" ; sleep 1 ;;
    esac
  done
  pause
}

hard_protector() {
  banner
  echo -e "${R}████  $TXT_HARD  ████${N}"
  echo -e "${R}$TXT_WARN_HARD${N}"
  echo -e "${Y}$TXT_SAFE${N}"
  echo
  echo "$TXT_CONFIRM:"
  printf "> "; read -r ok
  [ "$ok" = "YES" ] || return

  # Google layer
  local p
  for p in com.android.vending com.google.android.modulemetadata com.android.modulemetadata com.google.android.configupdater; do
    disable_pkg "$p" "hard_google" || true
  done

  # Detect manufacturer and apply a likely OTA profile.
  local man
  man="$(prop ro.product.manufacturer | tr '[:upper:]' '[:lower:]')"
  case "$man" in
    samsung*) samsung_profile ;;
    google*) pixel_components ;;
    nothing*) nothing_profile ;;
    *) try_find_updaters ;;
  esac

  # Root-only: cancel active update_engine transaction and stop current session.
  if [ "$BACKEND" = "root" ]; then
    x "command -v update_engine_client >/dev/null 2>&1 && update_engine_client --cancel" >/dev/null 2>&1 || true
    if x "getprop init.svc.update_engine" 2>/dev/null | grep -q '^running$'; then
      x "stop update_engine" >/dev/null 2>&1 || true
      log "${Y}[!] update_engine stopped for current boot session${N}"
    fi
  fi

  echo
  echo "$TXT_INSTALL_LOCK ($TXT_YN)"
  printf "> "; read -r inst
  case "$inst" in
    y|Y|yes|YES|ja|JA|是)
      # Deliberately NOT touching PermissionController/APEX.
      for p in com.google.android.packageinstaller com.android.packageinstaller com.samsung.android.packageinstaller; do
        disable_pkg "$p" "hard_installer_lock" || true
      done
      ;;
  esac
  pause
}

# Root-only and user-scoped. System APKs are backed up, but never deleted from
# their read-only partitions. `pm uninstall --user` removes only the current
# Android user's package registration; Reverse uses install-existing.
root_user_update_service_remover() {
  banner
  echo -e "${R}╔══════════════════════════════════════════════════════════════╗${N}"
  echo -e "${R}║                    $TXT_DANGER_HEAD${N}"
  echo -e "${R}╚══════════════════════════════════════════════════════════════╝${N}"
  echo

  if [ "$BACKEND" != "root" ]; then
    echo -e "${R}[x] $TXT_ROOT_ONLY${N}"
    pause
    return
  fi

  echo -e "${Y}$TXT_ROOT_REMOVE_DESC${N}"
  echo
  echo "$TXT_DANGER_STEP1:"
  printf "> "; read -r unlock
  [ "$unlock" = "Y" ] || return

  echo
  echo "$TXT_DANGER_STEP2:"
  printf "> "; read -r consent
  [ "$consent" = "$TXT_DANGER_TOKEN" ] || return

  echo
  echo -e "${R}██████████████████████████████████████████████████████████████${N}"
  echo -e "${R}$TXT_DANGER_WARNING${N}"
  echo -e "${R}██████████████████████████████████████████████████████████████${N}"
  printf '\n%s' "$TXT_DANGER_ACK"
  read -r _

  local uid stamp backup_device backup_termux tmp
  uid="$(x "am get-current-user" 2>/dev/null | tr -dc '0-9')"
  [ -n "$uid" ] || uid="0"
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_device="/storage/emulated/$uid/Documents/BackupsOSU/$stamp"
  backup_termux="$HOME/storage/shared/Documents/BackupsOSU/$stamp"
  tmp="$TARGET_DIR/root-remover-candidates.txt"

  # Restrict the destructive list to system packages with updater-like names.
  # This keeps install-existing available for reliable user-side reversal.
  x "pm list packages -s --user '$uid'" 2>/dev/null | tr -d '\r' | sed 's/^package://' \
    | grep -Ei '(wssync|soagent|(^|\.)sdm$|update|updater|ota|fota|firmware|softwareupdate|systemupdate)' \
    | grep -Evi '(systemui|webview|permission|settings|packageinstaller)' \
    | awk '!seen[$0]++' > "$tmp" || true

  mapfile -t REMOVE_CANDS < "$tmp"
  if [ ${#REMOVE_CANDS[@]} -eq 0 ]; then
    echo -e "${Y}$TXT_NONE${N}"
    rm -f "$tmp"
    pause
    return
  fi

  echo
  echo -e "${W}$TXT_SYSTEM_CANDIDATES (user $uid):${N}"
  local i=1 p
  for p in "${REMOVE_CANDS[@]}"; do
    printf " %2d) %s\n" "$i" "$p"
    i=$((i+1))
  done
  echo
  echo "$TXT_SELECT"
  printf "> "; read -r picks
  [ "$picks" = "0" ] && { rm -f "$tmp"; return; }

  if ! x "mkdir -p '$backup_device' && chmod 0775 '$backup_device'" >/dev/null 2>&1; then
    echo -e "${R}[x] $TXT_BACKUP_FAILED: $backup_device${N}"
    rm -f "$tmp"
    pause
    return
  fi

  local n paths apk apk_name pkg_backup backup_ok manifest
  manifest="$backup_termux/packages.tsv"
  if ! mkdir -p "$backup_termux" 2>/dev/null || ! printf 'package\tuser\tapk_paths\tcreated\n' > "$manifest" 2>/dev/null; then
    echo -e "${R}[x] $TXT_BACKUP_FAILED: $backup_termux${N}"
    rm -f "$tmp"
    pause
    return
  fi

  for n in $picks; do
    [[ "$n" =~ ^[0-9]+$ ]] || continue
    [ "$n" -ge 1 ] && [ "$n" -le "${#REMOVE_CANDS[@]}" ] || continue
    p="${REMOVE_CANDS[$((n-1))]}"
    if is_never_touch "$p"; then
      log "${Y}[SKIP] Never-Touch: $p${N}"
      continue
    fi

    paths="$(x "pm path '$p'" 2>/dev/null | tr -d '\r' | sed 's/^package://')"
    [ -n "$paths" ] || { log "${R}[x] $TXT_BACKUP_FAILED: $p${N}"; continue; }
    pkg_backup="$backup_device/$p"
    x "mkdir -p '$pkg_backup'" >/dev/null 2>&1 || { log "${R}[x] $TXT_BACKUP_FAILED: $p${N}"; continue; }

    backup_ok=1
    while IFS= read -r apk; do
      [ -n "$apk" ] || continue
      apk_name="${apk##*/}"
      if ! x "cp -p '$apk' '$pkg_backup/$apk_name' && chmod 0644 '$pkg_backup/$apk_name' && test -s '$pkg_backup/$apk_name'" >/dev/null 2>&1; then
        backup_ok=0
        break
      fi
    done <<< "$paths"
    if [ "$backup_ok" -ne 1 ]; then
      log "${R}[x] $TXT_BACKUP_FAILED: $p${N}"
      continue
    fi

    printf '%s\t%s\t%s\t%s\n' "$p" "$uid" "$(printf '%s' "$paths" | paste -sd ',' -)" "$(date -Iseconds 2>/dev/null || date)" >> "$manifest" 2>/dev/null || true
    if x "pm uninstall --user '$uid' '$p'" 2>/dev/null | tr -d '\r' | grep -q 'Success'; then
      grep -Fq "uninstalled|$p|" "$STATE_FILE" 2>/dev/null || echo "uninstalled|$p|$uid|root_user_remover" >> "$STATE_FILE"
      log "${G}[✓] $TXT_REMOVED_USER: $p (user $uid)${N}"
    else
      log "${R}[x] $TXT_FAILED: $p${N}"
    fi
  done

  rm -f "$tmp"
  echo
  echo -e "${Y}══════════════════════════════════════════════════════════════${N}"
  echo -e "${Y}[BACKUP] $TXT_BACKUP_SAVED:${N}"
  echo -e "${W}$backup_device${N}"
  echo -e "${Y}══════════════════════════════════════════════════════════════${N}"
  pause
}

# ---------- Reverse ----------
reverse_select() {
  banner
  [ -s "$STATE_FILE" ] || { echo "$TXT_NO_STATE"; pause; return; }
  mapfile -t LINES < "$STATE_FILE"
  local i=1 line kind item before reason
  for line in "${LINES[@]}"; do
    IFS='|' read -r kind item before reason <<< "$line"
    printf " %2d) %-9s %-65s [%s]\n" "$i" "$kind" "$item" "$reason"
    i=$((i+1))
  done
  echo
  echo "$TXT_SELECT"
  printf "> "; read -r picks
  [ "$picks" = "0" ] && return
  local keep="$STATE_FILE.keep" n
  : > "$keep"
  for i in "${!LINES[@]}"; do
    local selected=0 idx=$((i+1))
    for n in $picks; do [ "$n" = "$idx" ] && selected=1; done
    line="${LINES[$i]}"
    IFS='|' read -r kind item before reason <<< "$line"
    if [ "$selected" -eq 1 ]; then
      restore_item "$kind" "$item" "$before" || echo "$line" >> "$keep"
    else
      echo "$line" >> "$keep"
    fi
  done
  mv "$keep" "$STATE_FILE"
  pause
}

reverse_all() {
  banner
  [ -s "$STATE_FILE" ] || { echo "$TXT_NO_STATE"; pause; return; }
  local keep="$STATE_FILE.keep"
  : > "$keep"
  while IFS='|' read -r kind item before reason; do
    if [ -n "$item" ]; then
      restore_item "$kind" "$item" "$before" || echo "$kind|$item|$before|$reason" >> "$keep"
    fi
  done < "$STATE_FILE"
  mv "$keep" "$STATE_FILE"
  fast_fix
  echo -e "${G}[✓] $TXT_FIX${N}"
  pause
}

# ---------- Health / repair ----------
fast_fix() {
  # Restore core packages if they were disabled by some other tool. Does not touch user data.
  local core=(com.android.systemui com.android.settings)
  local p
  for p in "${core[@]}"; do
    if pkg_exists "$p" && pkg_disabled "$p"; then
      x "pm enable --user 0 '$p'" >/dev/null 2>&1 || true
    fi
  done
  # Clear temporary package-manager stopped states, not app data.
  x "am force-stop com.android.settings" >/dev/null 2>&1 || true
}

broken_checker() {
  local mode="${1:-normal}" issues=0
  banner
  echo "$TXT_CHECKING"
  echo

  check_pkg_health() {
    local p="$1" critical="$2"
    if ! pkg_exists "$p"; then
      echo -e "${Y}[?] missing: $p${N}"
      [ "$critical" = "1" ] && issues=$((issues+1))
    elif pkg_disabled "$p"; then
      echo -e "${R}[!] disabled: $p${N}"
      [ "$critical" = "1" ] && issues=$((issues+1))
    else
      echo -e "${G}[✓] enabled: $p${N}"
    fi
  }

  check_pkg_health com.android.systemui 1
  check_pkg_health com.android.settings 1
  check_pkg_health com.google.android.gms 0

  # Permission controller may be APK or APEX depending on build; only warn if all known forms absent.
  if ! pkg_exists com.google.android.permissioncontroller && ! pkg_exists com.google.android.permission && ! pkg_exists com.android.permissioncontroller; then
    echo -e "${Y}[?] PermissionController package not detected with common names${N}"
  fi

  # Package installer health
  local installers=(com.google.android.packageinstaller com.android.packageinstaller com.samsung.android.packageinstaller)
  local seen=0 p
  for p in "${installers[@]}"; do
    if pkg_exists "$p"; then
      seen=1
      pkg_disabled "$p" && echo -e "${Y}[!] installer disabled: $p${N}" || echo -e "${G}[✓] installer enabled: $p${N}"
    fi
  done
  [ "$seen" -eq 0 ] && echo -e "${D}[-] package installer uses another/current modular implementation${N}"

  # Basic services
  local boot
  boot="$(prop sys.boot_completed)"
  [ "$boot" = "1" ] || { echo -e "${R}[!] sys.boot_completed=$boot${N}"; issues=$((issues+1)); }

  if [ "$issues" -gt 0 ]; then
    echo
    echo -e "${R}$TXT_BROKEN: $issues${N}"
    if [ "$mode" = "repair" ]; then
      fast_fix
      echo -e "${Y}$TXT_FIX${N}"
    fi
  else
    echo
    echo -e "${G}$TXT_OK${N}"
  fi
  pause
}

reverse_hard_checker() {
  # Restore our own changes, then inspect core state.
  if [ -s "$STATE_FILE" ]; then
    local keep="$STATE_FILE.keep"
    : > "$keep"
    while IFS='|' read -r kind item before reason; do
      if [ -n "$item" ]; then
        restore_item "$kind" "$item" "$before" || echo "$kind|$item|$before|$reason" >> "$keep"
      fi
    done < "$STATE_FILE"
    mv "$keep" "$STATE_FILE"
  fi
  broken_checker repair
}

# ---------- Audit / report ----------
audit_to_stdout() {
  local model android patch fp man
  model="$(prop ro.product.model)"
  man="$(prop ro.product.manufacturer)"
  android="$(prop ro.build.version.release) / SDK $(prop ro.build.version.sdk)"
  patch="$(prop ro.build.version.security_patch)"
  fp="$(prop ro.build.fingerprint)"
  echo "$TXT_DEVICE: $man $model"
  echo "$TXT_ANDROID: $android"
  echo "$TXT_PATCH: $patch"
  echo "$TXT_FP: $fp"
  echo "$TXT_ACCESS: $BACKEND${ADB_SERIAL:+ ($ADB_SERIAL)}"
  echo
  echo "--- Google / update packages ---"
  local p
  for p in com.android.vending com.google.android.modulemetadata com.android.modulemetadata com.google.android.configupdater com.samsung.sdm com.wssyncmldm com.sec.android.soagent com.nothing.OfflineOTAUpgradeApp; do
    if pkg_exists "$p"; then
      if pkg_disabled "$p"; then printf "[DISABLED] %s\n" "$p"; else printf "[ENABLED ] %s\n" "$p"; fi
    fi
  done
  echo
  echo "--- discovered updater-like packages ---"
  x "pm list packages --user 0" 2>/dev/null | tr -d '\r' | sed 's/^package://' | grep -Ei '(update|updater|ota|fota|wssync|soagent|(^|\.)sdm$|firmware|softwareupdate|systemupdate)' | head -n 80 || true
  echo
  echo "--- CatCore UpdateGuard state ---"
  cat "$STATE_FILE" 2>/dev/null || true
}

audit_screen() {
  banner
  audit_to_stdout
  pause
}

export_report() {
  local f="$OUTDIR/CatCore-UpdateGuard-report-$(date +%Y%m%d-%H%M%S).txt"
  {
    echo "CatCore UpdateGuard $VER"
    echo "Generated: $(date)"
    echo
    audit_to_stdout
    echo
    echo "--- init update services ---"
    x "getprop" 2>/dev/null | grep -Ei 'init\.svc\..*(update|ota)|update_engine' || true
    echo
    echo "--- package disabled list ---"
    x "pm list packages -d --user 0" 2>/dev/null || true
  } > "$f"
  echo -e "${G}[✓] $TXT_REPORT_SAVED: $f${N}"
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    printf '%s' "$f" | termux-clipboard-set >/dev/null 2>&1 || true
  fi
  pause
}

# ---------- Main ----------
main_menu() {
  while :; do
    banner
    local model
    model="$(prop ro.product.manufacturer) $(prop ro.product.model)"
    echo -e "${D}$model  •  backend=$BACKEND${N}"
    echo -e "${Y}━━ $TXT_PROTECTION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${G} 1) $TXT_GP${N}"
    echo "    $TXT_GP_DESC"
    echo -e "${C} 2) $TXT_SYS${N}"
    echo "    $TXT_SYS_DESC"
    echo -e "${R} 3) $TXT_HARD${N}"
    echo -e "${R}    $TXT_HARD_DESC${N}"
    echo
    echo -e "${C}━━ $TXT_RECOVERY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo " 4) $TXT_REVSEL"
    echo " 5) $TXT_REVA"
    echo " 6) $TXT_REVH"
    echo " 7) $TXT_CHECK"
    echo
    echo -e "${B}━━ $TXT_TOOLS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo " 8) $TXT_AUDIT"
    echo " 9) $TXT_REPORT"
    echo
    echo -e "${R}10) $TXT_ROOT_REMOVE${N}"
    echo -e "${R}    $TXT_ROOT_REMOVE_DESC${N}"
    echo
    echo " 0) $TXT_EXIT"
    echo
    printf "> "; read -r c
    case "$c" in
      1) google_protector ;;
      2) disable_system_updates ;;
      3) hard_protector ;;
      4) reverse_select ;;
      5) reverse_all ;;
      6) reverse_hard_checker ;;
      7) broken_checker normal ;;
      8) audit_screen ;;
      9) export_report ;;
      10) root_user_update_service_remover ;;
      0) break ;;
      *) echo "$TXT_INVALID"; sleep 1 ;;
    esac
  done
}

select_backend
mk_target_state
main_menu
