#!/usr/bin/env sh
# Installer đa host cho mobile-plugin. POSIX shell, không dependency ngoài git/coreutils.
# Detect Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh` rồi cài plugin
# vào từng host bằng COPY (không bao giờ symlink — symlink cho phép host ghi ngược vào repo).
# Hỏi thêm scope: user (global, giống team-plugin) hoặc project (đúng thư mục đang đứng khi
# gọi script này). Không có hook nào trong plugin này, khác team-plugin.
# Idempotent; một host lỗi không chặn host khác.
# Usage: ./install.sh [--dry-run] [--only claude,agy,dsh] [--scope user|project]
set -eu

MARKER=".mobile-plugin" # ghi vào mọi thư mục installer sở hữu; không có marker thì không đè
# Core = mọi thứ trừ danh sách này. File riêng của host: .claude-plugin/ (Claude), .agents/ (Antigravity, dsh).
SKIP=".git .history .polaris .DS_Store node_modules __pycache__ docs .agents .claude .claude-plugin"

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
HOME_DIR=${HOME:?}
PROJECT_DIR=$(pwd -P) # thư mục user đang đứng lúc gọi ./install.sh — dùng cho scope=project
DRY_RUN=0
ONLY=""
SCOPE=""

while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --only) ONLY=$(printf '%s' "${2:-}" | tr ',' ' '); shift ;;
    --scope) SCOPE=${2:-}; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "tham số lạ: $1" >&2; exit 1 ;;
  esac
  shift
done
for k in $ONLY; do
  case $k in claude|agy|dsh) ;; *) echo "--only nhận: claude,agy,dsh" >&2; exit 1 ;; esac
done
case $SCOPE in ""|user|project) ;; *) echo "--scope nhận: user,project" >&2; exit 1 ;; esac

# ---- helpers ----
have() { command -v "$1" >/dev/null 2>&1; }
log() { echo "[$1] $2"; }

# TTY dùng chung cho mọi prompt. Không có TTY thì mọi câu hỏi trả lời "không" — không tự ý side-effect trong script.
IS_TTY=0
{ [ -t 0 ] && [ -r /dev/tty ] && IS_TTY=1; } || true

# Đọc 1 byte từ /dev/tty ở raw mode, trả mã thập phân (rỗng khi EOF).
read_byte() { dd bs=1 count=1 2>/dev/null < /dev/tty | od -An -tu1 | tr -d ' \n'; }

# Multi-select bằng phím mũi tên trên danh sách $@ (mặc định chọn hết).
# ↑↓/k/j đổi dòng, Space bật/tắt, a = chọn hết, Enter xác nhận, q/Esc/Ctrl-C thoát.
# Kết quả ghi vào PICKED (rỗng = không chọn gì); return 1 khi user thoát.
pick() {
  title=$1; shift
  items=$*; n=0
  for _ in $items; do n=$((n + 1)); done
  cur=0; sel=" "
  i=0; for _ in $items; do sel="$sel$i "; i=$((i + 1)); done

  draw() {
    [ "${1:-}" = first ] || printf '\033[%dA' "$((n + 1))" > /dev/tty
    printf '%s\033[K\r\n' "$title" > /dev/tty
    i=0
    for it in $items; do
      [ "$i" = "$cur" ] && ptr=">" || ptr=" "
      case $sel in *" $i "*) mark="x" ;; *) mark=" " ;; esac
      printf '%s [%s] %s\033[K\r\n' "$ptr" "$mark" "$it" > /dev/tty
      i=$((i + 1))
    done
  }

  saved=$(stty -g < /dev/tty)
  stty raw -echo < /dev/tty
  draw first
  while :; do
    b=$(read_byte)
    case $b in
      27) # Esc hoặc mở đầu escape sequence của phím mũi tên
        b2=$(read_byte)
        [ "$b2" = 91 ] || break
        case $(read_byte) in
          65) cur=$(((cur - 1 + n) % n)) ;;
          66) cur=$(((cur + 1) % n)) ;;
          *) continue ;;
        esac ;;
      107) cur=$(((cur - 1 + n) % n)) ;;               # k
      106) cur=$(((cur + 1) % n)) ;;                   # j
      32) case $sel in                                 # Space
            *" $cur "*) sel=$(printf '%s' "$sel" | sed "s/ $cur / /") ;;
            *) sel="$sel$cur " ;;
          esac ;;
      97) sel=" "; i=0                                 # a = chọn hết
          for _ in $items; do sel="$sel$i "; i=$((i + 1)); done ;;
      13|10) # Enter
        stty "$saved" < /dev/tty
        PICKED=""; i=0
        for it in $items; do
          case $sel in *" $i "*) PICKED="$PICKED $it" ;; esac
          i=$((i + 1))
        done
        return 0 ;;
      113|3|"") break ;;                               # q, Ctrl-C, EOF
      *) continue ;;
    esac
    draw
  done
  stty "$saved" < /dev/tty
  return 1
}

# Single-select bằng phím mũi tên trên danh sách "$@" (↑↓/k/j, số 1-9 chọn nhanh, Enter xác nhận,
# q/Esc/Ctrl-C huỷ; số chỉ di chuyển con trỏ, Enter mới chốt). Kết quả: CHOICE (nhãn) + CHOICE_IDX (0-based); return 1 khi huỷ hoặc không có TTY.
choose() {
  [ "$IS_TTY" = 1 ] || return 1
  title=$1; shift
  n=$#; cur=0; first=1
  saved=$(stty -g < /dev/tty)
  stty raw -echo < /dev/tty
  while :; do
    [ "$first" = 1 ] || printf '\033[%dA' "$((n + 1))" > /dev/tty
    first=0
    printf '%s\033[K\r\n' "$title" > /dev/tty
    i=0
    for it in "$@"; do
      [ "$i" = "$cur" ] && ptr=">" || ptr=" "
      printf '%s %d. %s\033[K\r\n' "$ptr" "$((i + 1))" "$it" > /dev/tty
      i=$((i + 1))
    done
    b=$(read_byte)
    case $b in
      27) b2=$(read_byte)
          [ "$b2" = 91 ] || { stty "$saved" < /dev/tty; return 1; }
          case $(read_byte) in
            65) cur=$(((cur - 1 + n) % n)) ;;
            66) cur=$(((cur + 1) % n)) ;;
          esac ;;
      107) cur=$(((cur - 1 + n) % n)) ;;                 # k
      106) cur=$(((cur + 1) % n)) ;;                     # j
      49|50|51|52|53|54|55|56|57)                        # 1-9 nhảy tới dòng đó, vẫn cần Enter
        d=$((b - 49))
        [ "$d" -lt "$n" ] && cur=$d ;;
      113|3|"") stty "$saved" < /dev/tty; return 1 ;;    # q, Ctrl-C, EOF
    esac
    if [ "$b" = 13 ] || [ "$b" = 10 ]; then
      stty "$saved" < /dev/tty
      CHOICE_IDX=$cur; i=0
      for it in "$@"; do
        [ "$i" = "$cur" ] && { CHOICE=$it; return 0; }
        i=$((i + 1))
      done
    fi
  done
}

# Yes/No dạng selection. Mặc định con trỏ ở Yes.
confirm() { choose "$1" "Yes" "No" && [ "$CHOICE_IDX" = 0 ]; }

# Đường dẫn tuyệt đối kể cả khi phần đuôi chưa tồn tại.
abspath() {
  d=$(dirname -- "$1"); b=$(basename -- "$1")
  while [ ! -d "$d" ]; do b="$(basename -- "$d")/$b"; d=$(dirname -- "$d"); done
  printf '%s/%s\n' "$(CDPATH= cd -- "$d" && pwd -P)" "$b"
}

skipped() {
  for s in $SKIP; do [ "$1" = "$s" ] && return 0; done
  return 1
}

# Thay `dst` bằng bản copy đã lọc của `src`. Chỉ đè thư mục có MARKER. In kết quả ra stdout.
copy_dir() {
  src=$1; dst=$2
  if [ -L "$dst" ]; then
    echo "lỗi: $dst là symlink — installer chỉ copy; xoá rồi chạy lại"; return 0
  fi
  s=$(abspath "$src"); t=$(abspath "$dst")
  case $s in
    "$t"|"$t"/*) echo "lỗi: $dst chứa chính nguồn — chạy install.sh từ repo"; return 0 ;;
  esac
  existed=0
  if [ -e "$dst" ]; then
    [ -d "$dst" ] || { echo "lỗi: $dst không phải thư mục, gỡ tay"; return 0; }
    [ -f "$dst/$MARKER" ] || { echo "lỗi: $dst không do installer tạo, gỡ tay"; return 0; }
    existed=1
  fi
  if [ "$DRY_RUN" = 1 ]; then
    [ "$existed" = 1 ] && echo "sẽ copy đè" || echo "sẽ copy"
    return 0
  fi
  rm -rf "$dst"
  mkdir -p "$dst"
  for entry in "$src"/* "$src"/.[!.]*; do
    [ -e "$entry" ] || continue
    skipped "$(basename -- "$entry")" && continue
    cp -R "$entry" "$dst/"
  done
  find "$dst" \( -name __pycache__ -o -name .DS_Store \) -prune -exec rm -rf {} + 2>/dev/null || true
  echo "installed by mobile-plugin install.sh" > "$dst/$MARKER"
  [ "$existed" = 1 ] && echo "đã copy đè" || echo "đã copy"
}

# ---- detect host ----
CLAUDE_DIR=${CLAUDE_CONFIG_DIR:-$HOME_DIR/.claude}
DSH_DIR=${DSH_HOME:-$HOME_DIR/.dsh}
AGY_PLUGINS_USER="$HOME_DIR/.gemini/config/plugins"

present() {
  case $1 in
    claude) [ -d "$CLAUDE_DIR" ] ;;
    agy) [ -d "$HOME_DIR/.gemini/config" ] || [ -d "$HOME_DIR/.gemini/antigravity-cli" ] ;;
    dsh) [ -d "$DSH_DIR" ] ;;
  esac
}
# agy/dsh detect bằng thư mục: IDE không có binary `agy`, dsh chạy qua npx.
agy_bin() {
  if have agy; then command -v agy
  elif [ -x "$HOME_DIR/.local/bin/agy" ]; then echo "$HOME_DIR/.local/bin/agy"
  fi
}

remote_url() {
  git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "$REPO_ROOT"
}

# ---- install từng host, theo scope (user = global host dir, project = $PROJECT_DIR) ----
install_claude() {
  bin=$(command -v claude 2>/dev/null || true)
  if [ -z "$bin" ]; then
    log claude "chưa có CLI, gõ tay:"
    echo "  claude plugin marketplace add $REMOTE --scope $SCOPE"
    echo "  claude plugin install mobile-dev@mobile --scope $SCOPE"
    echo "cần làm tay"; return 0
  fi
  # scope=project: các lệnh claude phải chạy với cwd = project đang đứng để CLI ghi cấu hình đúng chỗ.
  run_claude() { if [ "$SCOPE" = project ]; then ( cd "$PROJECT_DIR" && "$bin" "$@" ); else "$bin" "$@"; fi; }

  log claude "claude plugin list (scope=$SCOPE)"
  if run_claude plugin list 2>/dev/null | grep -q 'mobile-dev@mobile'; then
    [ "$DRY_RUN" = 1 ] && { echo "đã cài — sẽ hỏi update"; return 0; }
    confirm "[claude] mobile-dev@mobile ($SCOPE) đã cài. Update lên bản mới?" || { echo "đã cài, bỏ qua"; return 0; }
    log claude "claude plugin marketplace update mobile"
    run_claude plugin marketplace update mobile || { echo "lỗi: marketplace update thất bại"; return 0; }
    log claude "claude plugin update mobile-dev@mobile"
    out=$(run_claude plugin update mobile-dev@mobile 2>&1) || { printf '%s\n' "$out"; echo "lỗi: plugin update thất bại"; return 0; }
    printf '%s\n' "$out"
    if printf '%s' "$out" | grep -qi 'latest version'; then
      echo "đã ở bản mới nhất — quên bump version trong .claude-plugin/plugin.json?"
    else
      echo "đã update"
    fi
    return 0
  fi
  if ! run_claude plugin marketplace list 2>/dev/null | grep -q 'mobile'; then
    log claude "claude plugin marketplace add $REMOTE --scope $SCOPE"
    [ "$DRY_RUN" = 1 ] || run_claude plugin marketplace add "$REMOTE" --scope "$SCOPE" || true
  fi
  log claude "claude plugin install mobile-dev@mobile --scope $SCOPE"
  [ "$DRY_RUN" = 1 ] && { echo "sẽ cài"; return 0; }
  run_claude plugin install mobile-dev@mobile --scope "$SCOPE" -y && echo "đã cài" || echo "lỗi: install thất bại"
}

install_agy() {
  dst_root=$([ "$SCOPE" = project ] && echo "$PROJECT_DIR/.agents" || echo "$AGY_PLUGINS_USER")
  bin=$(agy_bin)
  if [ -n "$bin" ] && [ "$SCOPE" = user ]; then
    # Dựng bản copy đã lọc để agy không kéo .git/.history vào thư mục plugin của nó. Chỉ dùng cho user scope
    # (agy CLI cài vào thư mục global của nó; project scope ghi thẳng ra $PROJECT_DIR/.agents bằng copy_dir bên dưới).
    log agy "agy plugin install <bản lọc của $REPO_ROOT>"
    [ "$DRY_RUN" = 1 ] && { echo "sẽ cài qua agy"; return 0; }
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/mobile-plugin.XXXXXX")
    stage="$tmp/mobile-dev"
    res=$(copy_dir "$REPO_ROOT" "$stage")
    case $res in lỗi*) rm -rf "$tmp"; echo "$res"; return 0 ;; esac
    cp "$REPO_ROOT/.agents/plugin.json" "$stage/plugin.json"
    cp "$REPO_ROOT/.agents/AGENTS.md" "$stage/rules/AGENTS.md"
    if [ -d "$AGY_PLUGINS_USER/mobile-dev" ] && ! "$bin" plugin uninstall mobile-dev >/dev/null 2>&1; then
      rm -rf "$tmp"
      echo "lỗi: agy plugin uninstall thất bại, gỡ $AGY_PLUGINS_USER/mobile-dev tay"; return 0
    fi
    "$bin" plugin install "$stage" && out="đã cài qua agy" || out="lỗi: agy plugin install thất bại"
    rm -rf "$tmp"
    echo "$out"; return 0
  fi
  dst="$dst_root/mobile-dev"
  log agy "copy $REPO_ROOT -> $dst (scope=$SCOPE)"
  res=$(copy_dir "$REPO_ROOT" "$dst")
  case $res in
    lỗi*) : ;;
    *) if [ "$DRY_RUN" = 0 ]; then
         cp "$REPO_ROOT/.agents/plugin.json" "$dst/plugin.json"
         cp "$REPO_ROOT/.agents/AGENTS.md" "$dst/rules/AGENTS.md"
       fi ;;
  esac
  echo "$res"
}

install_dsh() {
  skills_root=$([ "$SCOPE" = project ] && echo "$PROJECT_DIR/.agents/skills" || echo "$HOME_DIR/.agents/skills")
  plugin_root=$([ "$SCOPE" = project ] && echo "$PROJECT_DIR/.agents/mobile-dev" || echo "$HOME_DIR/.agents/mobile-dev")
  agents_md=$([ "$SCOPE" = project ] && echo "$PROJECT_DIR/.dsh/AGENTS.md" || echo "$DSH_DIR/AGENTS.md")

  results=""
  for skill in "$REPO_ROOT"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename -- "$skill")
    dst="$skills_root/$name"
    log dsh "copy ${skill%/} -> $dst (scope=$SCOPE)"
    results="$results; $(copy_dir "${skill%/}" "$dst")"
  done
  log dsh "copy $REPO_ROOT -> $plugin_root (scope=$SCOPE)"
  plugin_res=$(copy_dir "$REPO_ROOT" "$plugin_root")
  results="$results; $plugin_res"
  case $plugin_res in
    lỗi*) : ;;
    *) [ "$DRY_RUN" = 0 ] && cp "$REPO_ROOT/.agents/AGENTS.md" "$plugin_root/rules/AGENTS.md" || true ;;
  esac

  open="<!-- mobile-plugin -->"; close="<!-- /mobile-plugin -->"
  log dsh "block mobile-plugin trong $agents_md"
  block="$open
Mobile plugin root: $plugin_root — read $plugin_root/rules/AGENTS.md first.
$close"
  if [ "$DRY_RUN" = 1 ]; then
    if [ -f "$agents_md" ] && grep -qF "$open" "$agents_md"; then
      results="$results; sẽ cập nhật AGENTS.md"
    else
      results="$results; sẽ append AGENTS.md"
    fi
  else
    mkdir -p "$(dirname -- "$agents_md")"
    had=0
    if [ -f "$agents_md" ] && grep -qF "$open" "$agents_md"; then
      had=1
      # BSD awk không nhận -v chứa newline, nên xoá block cũ rồi append block mới thay vì thay tại chỗ.
      awk -v o="$open" -v c="$close" '$0 == o { s = 1; next } s { if ($0 == c) s = 0; next } { print }' \
        "$agents_md" > "$agents_md.new" && mv "$agents_md.new" "$agents_md"
    fi
    if [ -s "$agents_md" ] && [ -n "$(tail -c 1 "$agents_md")" ]; then printf '\n' >> "$agents_md"; fi
    printf '%s\n' "$block" >> "$agents_md"
    [ "$had" = 1 ] && results="$results; đã cập nhật AGENTS.md" || results="$results; đã append AGENTS.md"
  fi
  errs=$(printf '%s' "$results" | tr ';' '\n' | grep '^ *lỗi' || true)
  if [ -n "$errs" ]; then printf '%s' "$errs" | tr '\n' ';' ; echo; else
    # Mỗi skill trả cùng một kết quả; gộp dòng trùng thành "<n>x <kết quả>", giữ thứ tự gặp đầu.
    printf '%s' "$results" | tr ';' '\n' |
      awk 'NF { sub(/^ +/, ""); if (!($0 in c)) o[++k] = $0; c[$0]++ }
           END { for (i = 1; i <= k; i++) printf "%s%s%s", (i > 1 ? "; " : ""), (c[o[i]] > 1 ? c[o[i]] "x " : ""), o[i]; print "" }'
  fi
}

# ---- main ----
REMOTE=$(remote_url)

if [ -z "$SCOPE" ]; then
  if [ "$IS_TTY" != 1 ]; then
    echo "stdin không phải TTY — chọn scope bằng --scope user|project" >&2
    exit 1
  fi
  choose "Cài scope nào? user = global ($CLAUDE_DIR ...); project = $PROJECT_DIR" "user" "project" || exit 0
  SCOPE=$CHOICE
fi
echo "scope: $SCOPE $([ "$SCOPE" = project ] && echo "(project = $PROJECT_DIR)")"

echo "host   | detect  | kết quả"
row() { printf '%-6s | %-7s | %s\n' "$1" "$2" "$3"; }

FOUND=""
for k in claude agy dsh; do present "$k" && FOUND="$FOUND $k"; done
if [ -z "$FOUND" ]; then
  for k in claude agy dsh; do row "$k" "không" "không phát hiện"; done
  exit 1
fi

CHOSEN=$ONLY
if [ -z "$CHOSEN" ]; then
  for k in claude agy dsh; do
    if present "$k"; then row "$k" "có" "sẵn sàng cài"; else row "$k" "không" "—"; fi
  done
  if [ "$IS_TTY" != 1 ]; then
    echo "stdin không phải TTY — chọn host bằng --only claude,agy,dsh" >&2
    exit 1
  fi
  pick "Cài host nào? (↑↓ chọn dòng, Space bật/tắt, a = tất cả, Enter xác nhận, q = thoát)" $FOUND || exit 0
  CHOSEN=$PICKED
  if [ -z "$CHOSEN" ]; then echo "Không chọn host nào — thoát."; exit 0; fi
fi

FAILED=0
ROWS=""
for k in $CHOSEN; do
  if ! present "$k"; then ROWS="$ROWS$k|không|không phát hiện
"; continue; fi
  log "$k" "bắt đầu"
  case $k in
    claude) res=$(install_claude) ;;
    agy) res=$(install_agy) ;;
    dsh) res=$(install_dsh) ;;
  esac
  # install_* in log ra stdout lẫn kết quả; lấy dòng cuối làm kết quả, in phần còn lại.
  printf '%s\n' "$res" | sed '$d'
  ROWS="$ROWS$k|có|$(printf '%s\n' "$res" | tail -n 1)
"
done

echo
echo "host   | detect  | kết quả"
printf '%s' "$ROWS" | while IFS='|' read -r h dt rs; do
  [ -n "$h" ] || continue
  row "$h" "$dt" "$rs"
done
printf '%s' "$ROWS" | grep -q '|lỗi' && FAILED=1 || true

echo "Restart session của từng host để nạp plugin. Antigravity/dsh là bản copy: sửa repo xong chạy lại \`./install.sh --scope $SCOPE\`; Claude cập nhật qua marketplace."

[ "$FAILED" = 0 ] || exit 1
