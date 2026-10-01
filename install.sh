#!/usr/bin/env sh
# Multi-host installer for mobile-plugin. POSIX shell, no dependencies beyond git/coreutils.
# Detects Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh`, then installs the plugin
# into each host by COPY (never symlink — a symlink lets the host write back into the repo).
# Also asks for scope: user (global, like team-plugin) or project (the directory you are in when
# calling this script). This plugin has no hooks, unlike team-plugin.
# Idempotent; one host failing does not block the others.
# Usage: ./install.sh [--dry-run] [--only claude,agy,dsh] [--pack flutter,android,ios,rn] [--scope user|project] [--project <path>]
#   --pack: sub-plugins to install (mobile-<pack>); if omitted, asks via menu.
#   --project: target project dir for scope=project (default: current dir; asks if you are inside this repo).
set -eu

# Core = everything except this list. Host-specific files: .claude-plugin/ (Claude), .agents/ (Antigravity, dsh).
SKIP=".git .history .polaris .DS_Store node_modules __pycache__ docs .agents .claude .claude-plugin"

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
HOME_DIR=${HOME:?}
PROJECT_DIR=$(pwd -P) # directory the user is in when calling ./install.sh — used for scope=project
DRY_RUN=0
ONLY=""
PACKS=""
SCOPE=""
ALL_PACKS="flutter android ios rn"

while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --only) ONLY=$(printf '%s' "${2:-}" | tr ',' ' '); shift ;;
    --pack) PACKS=$(printf '%s' "${2:-}" | tr ',' ' '); shift ;;
    --scope) SCOPE=${2:-}; shift ;;
    --project) PROJECT_DIR=${2:-}; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done
for k in $ONLY; do
  case $k in claude|agy|dsh) ;; *) echo "--only accepts: claude,agy,dsh" >&2; exit 1 ;; esac
done
for k in $PACKS; do
  case $k in flutter|android|ios|rn) ;; *) echo "--pack accepts: flutter,android,ios,rn" >&2; exit 1 ;; esac
done
case $SCOPE in ""|user|project) ;; *) echo "--scope accepts: user,project" >&2; exit 1 ;; esac

# ---- helpers ----
have() { command -v "$1" >/dev/null 2>&1; }
log() { echo "[$1] $2"; }

# Shared TTY for every prompt. Without a TTY every question answers "no" — the script never causes side effects on its own.
IS_TTY=0
{ [ -t 0 ] && [ -r /dev/tty ] && IS_TTY=1; } || true

# Read 1 byte from /dev/tty in raw mode, return the decimal code (empty on EOF).
read_byte() { dd bs=1 count=1 2>/dev/null < /dev/tty | od -An -tu1 | tr -d ' \n'; }
# Arrow-key multi-select over the list $@ (all selected by default; `--none` first = nothing selected).
# Arrow-key multi-select over the list $@ (all selected by default).
# Up/Down/k/j move, Space toggles, a = select all, Enter confirms, q/Esc/Ctrl-C quits.
# Result goes into PICKED (empty = nothing selected); returns 1 when the user quits.
pick() {
  none=0; [ "$1" = --none ] && { none=1; shift; }
  title=$1; shift
  items=$*; n=0
  for _ in $items; do n=$((n + 1)); done
  cur=0; sel=" "
  [ "$none" = 1 ] || { i=0; for _ in $items; do sel="$sel$i "; i=$((i + 1)); done; }

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
      27) # Esc or start of an arrow-key escape sequence
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
      97) sel=" "; i=0                                 # a = select all
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

# Arrow-key single-select over the list "$@" (Up/Down/k/j, digits 1-9 jump, Enter confirms,
# q/Esc/Ctrl-C cancels; digits only move the cursor, Enter commits). Result: CHOICE (label) + CHOICE_IDX (0-based); returns 1 on cancel or no TTY.
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
      49|50|51|52|53|54|55|56|57)                        # 1-9 jump to that row, Enter still required
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

# Yes/No as a selection. Cursor defaults to Yes.
confirm() { choose "$1" "Yes" "No" && [ "$CHOICE_IDX" = 0 ]; }

# Absolute path even when the tail does not exist yet.
abspath() {
  d=$(dirname -- "$1"); b=$(basename -- "$1")
  while [ ! -d "$d" ]; do b="$(basename -- "$d")/$b"; d=$(dirname -- "$d"); done
  printf '%s/%s\n' "$(CDPATH= cd -- "$d" && pwd -P)" "$b"
}

skipped() {
  for s in $SKIP; do [ "$1" = "$s" ] && return 0; done
  return 1
}

# Replace `dst` with a filtered copy of `src` (overwrite if present). Prints the result to stdout.
copy_dir() {
  src=$1; dst=$2
  if [ -L "$dst" ]; then
    echo "error: $dst is a symlink — installer only copies; remove it and rerun"; return 0
  fi
  s=$(abspath "$src"); t=$(abspath "$dst")
  case $s in
    "$t"|"$t"/*) echo "error: $dst contains the source itself — run install.sh from the repo"; return 0 ;;
  esac
  existed=0
  if [ -e "$dst" ]; then
    [ -d "$dst" ] || { echo "error: $dst is not a directory, remove it manually"; return 0; }
    existed=1
  fi
  if [ "$DRY_RUN" = 1 ]; then
    [ "$existed" = 1 ] && echo "would overwrite" || echo "would copy"
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
  [ "$existed" = 1 ] && echo "overwritten" || echo "copied"
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
# agy/dsh are detected by directory: the IDE has no `agy` binary, dsh runs via npx.
agy_bin() {
  if have agy; then command -v agy
  elif [ -x "$HOME_DIR/.local/bin/agy" ]; then echo "$HOME_DIR/.local/bin/agy"
  fi
}

remote_url() {
  git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "$REPO_ROOT"
}

# ---- install per host, by scope (user = global host dir, project = $PROJECT_DIR) ----
install_claude() {
  bin=$(command -v claude 2>/dev/null || true)
  if [ -z "$bin" ]; then
    log claude "CLI not found, run manually:"
    echo "  claude plugin marketplace add $REMOTE --scope $SCOPE"
    for pk in $PACKS; do echo "  claude plugin install mobile-$pk@mobile --scope $SCOPE"; done
    echo "manual step needed"; return 0
  fi
  # scope=project: claude commands must run with cwd = the project so the CLI writes config in the right place.
  run_claude() { if [ "$SCOPE" = project ]; then ( cd "$PROJECT_DIR" && "$bin" "$@" ); else "$bin" "$@"; fi; }

  # `plugin list` prints every entry of every project; filter by scope + projectPath to avoid matching an install in another project.
  claude_installed() {
    run_claude plugin list --json 2>/dev/null |
      awk -v want_id="\"$1\"" -v want_scope="$SCOPE" -v want_path="${PROJECT_DIR:-}" '
        /"id":/ { id = $0 } /"scope":/ { sc = $0 } /"projectPath":/ { pp = $0 }
        /^ *}/ { if (index(id, want_id) && sc ~ "\"" want_scope "\"" &&
                     (want_scope != "project" || pp ~ "\"" want_path "\"")) found = 1
                 id = sc = pp = "" }
        END { exit !found }'
  }

  log claude "claude plugin list (scope=$SCOPE)"
  claude_installed mobile-dev@mobile &&
    echo "warning: old mobile-dev@mobile still installed — remove with: claude plugin uninstall mobile-dev@mobile --scope $SCOPE"
  if ! run_claude plugin marketplace list 2>/dev/null | grep -q 'mobile'; then
    log claude "claude plugin marketplace add $REMOTE --scope $SCOPE"
    [ "$DRY_RUN" = 1 ] || run_claude plugin marketplace add "$REMOTE" --scope "$SCOPE" || true
  elif [ "$DRY_RUN" = 0 ]; then
    run_claude plugin marketplace update mobile >/dev/null 2>&1 || echo "error: marketplace update failed"
  fi
  results=""
  for pk in $PACKS; do
    id="mobile-$pk@mobile"
    if claude_installed "$id"; then
      [ "$DRY_RUN" = 1 ] && { results="$results; $id: will ask to update"; continue; }
      confirm "[claude] $id ($SCOPE) already installed. Update to the new version?" || { results="$results; $id: skipped"; continue; }
      log claude "claude plugin update $id --scope $SCOPE"
      out=$(run_claude plugin update "$id" --scope "$SCOPE" -y 2>&1) || { printf '%s\n' "$out"; results="$results; error: update $id"; continue; }
      printf '%s\n' "$out"
      if printf '%s' "$out" | grep -qi 'latest version'; then
        results="$results; $id: already latest (forgot to bump version?)"
      else results="$results; $id: updated"; fi
      continue
    fi
    log claude "claude plugin install $id --scope $SCOPE"
    [ "$DRY_RUN" = 1 ] && { results="$results; $id: would install"; continue; }
    run_claude plugin install "$id" --scope "$SCOPE" -y >/dev/null 2>&1 && results="$results; $id: installed" || results="$results; error: install $id"
  done
  summarize "$results"
}

# Build a flat tree rules/ skills/ agents/ commands/ (+ .mcp.json for flutter) from the selected packs —
# rule file names differ per pack (flutter.md, android.md...) so merging does not overwrite.
# Antigravity/dsh receive one merged mobile-dev plugin; they have no concept of sub-plugins.
build_stage() {
  STAGE_TMP=$(mktemp -d "${TMPDIR:-/tmp}/mobile-plugin.XXXXXX")
  STAGE="$STAGE_TMP/mobile-dev"
  mkdir -p "$STAGE/rules" "$STAGE/skills" "$STAGE/agents" "$STAGE/commands"
  for pk in $PACKS; do
    src="$REPO_ROOT/plugins/mobile-$pk"
    for d in rules skills agents commands; do
      [ -d "$src/$d" ] && cp -R "$src/$d/." "$STAGE/$d/"
    done
    [ -f "$src/.mcp.json" ] && cp "$src/.mcp.json" "$STAGE/.mcp.json"
  done
  return 0
}

install_agy() {
  bin=$(agy_bin)
  if [ -n "$bin" ]; then
    # Build a filtered copy so agy does not pull .git/.history into its plugin dir (user scope only —
    # project scope goes through install_project_agents because Antigravity does not load plugins from <project>/.agents/<name>/).
    log agy "agy plugin install <merged packs: $PACKS>"
    [ "$DRY_RUN" = 1 ] && { echo "would install via agy"; return 0; }
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/mobile-plugin.XXXXXX")
    stage="$tmp/mobile-dev"
    res=$(copy_dir "$STAGE" "$stage")
    case $res in error*) rm -rf "$tmp"; echo "$res"; return 0 ;; esac
    cp "$REPO_ROOT/.agents/plugin.json" "$stage/plugin.json"
    cp "$REPO_ROOT/.agents/AGENTS.md" "$stage/rules/AGENTS.md"
    if [ -d "$AGY_PLUGINS_USER/mobile-dev" ] && ! "$bin" plugin uninstall mobile-dev >/dev/null 2>&1; then
      rm -rf "$tmp"
      echo "error: agy plugin uninstall failed, remove $AGY_PLUGINS_USER/mobile-dev manually"; return 0
    fi
    "$bin" plugin install "$stage" && out="installed via agy" || out="error: agy plugin install failed"
    rm -rf "$tmp"
    echo "$out"; return 0
  fi
  dst="$AGY_PLUGINS_USER/mobile-dev"
  log agy "copy <merged packs: $PACKS> -> $dst"
  res=$(copy_dir "$STAGE" "$dst")
  case $res in
    error*) : ;;
    *) if [ "$DRY_RUN" = 0 ]; then
         cp "$REPO_ROOT/.agents/plugin.json" "$dst/plugin.json"
         cp "$REPO_ROOT/.agents/AGENTS.md" "$dst/rules/AGENTS.md"
       fi ;;
  esac
  echo "$res"
}

# Replace/append the <!-- mobile-plugin --> block in file $1 with content $2. Prints the result to stdout.
write_block() {
  f=$1; open="<!-- mobile-plugin -->"; close="<!-- /mobile-plugin -->"
  if [ "$DRY_RUN" = 1 ]; then
    if [ -f "$f" ] && grep -qF "$open" "$f"; then echo "would update $(basename -- "$f")"; else echo "would append $(basename -- "$f")"; fi
    return 0
  fi
  mkdir -p "$(dirname -- "$f")"
  had=0
  if [ -f "$f" ] && grep -qF "$open" "$f"; then
    had=1
    # BSD awk rejects -v values containing newlines, so delete the old block and append the new one instead of replacing in place.
    awk -v o="$open" -v c="$close" '$0 == o { s = 1; next } s { if ($0 == c) s = 0; next } { print }' \
      "$f" > "$f.new" && mv "$f.new" "$f"
  fi
  if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then printf '\n' >> "$f"; fi
  printf '%s\n%s\n%s\n' "$open" "$2" "$close" >> "$f"
  [ "$had" = 1 ] && echo "updated $(basename -- "$f")" || echo "appended $(basename -- "$f")"
}

# Collapse a result list "; a; a; b" into "2x a; b" (first-seen order); if there are errors, print only the errors.
summarize() {
  errs=$(printf '%s' "$1" | tr ';' '\n' | grep '^ *error' || true)
  if [ -n "$errs" ]; then printf '%s' "$errs" | tr '\n' ';' ; echo; else
    printf '%s' "$1" | tr ';' '\n' |
      awk 'NF { sub(/^ +/, ""); if (!($0 in c)) o[++k] = $0; c[$0]++ }
           END { for (i = 1; i <= k; i++) printf "%s%s%s", (i > 1 ? "; " : ""), (c[o[i]] > 1 ? c[o[i]] "x " : ""), o[i]; print "" }'
  fi
}

install_dsh() {
  results=""
  for skill in "$STAGE"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename -- "$skill")
    dst="$HOME_DIR/.agents/skills/$name"
    log dsh "copy ${skill%/} -> $dst"
    results="$results; $(copy_dir "${skill%/}" "$dst")"
  done
  plugin_root="$HOME_DIR/.agents/mobile-dev"
  log dsh "copy <merged packs: $PACKS> -> $plugin_root"
  plugin_res=$(copy_dir "$STAGE" "$plugin_root")
  results="$results; $plugin_res"
  case $plugin_res in
    error*) : ;;
    *) [ "$DRY_RUN" = 0 ] && cp "$REPO_ROOT/.agents/AGENTS.md" "$plugin_root/rules/AGENTS.md" || true ;;
  esac
  log dsh "mobile-plugin block in $DSH_DIR/AGENTS.md"
  results="$results; $(write_block "$DSH_DIR/AGENTS.md" "Mobile plugin root: $plugin_root — read $plugin_root/rules/AGENTS.md first.")"
  summarize "$results"
}

# scope=project — shared by agy + dsh, runs once. Both hosts only read these in a project:
#   skill: <project>/.agents/skills/<name>/ (agy + dsh)
#   rule:  <project>/.agents/rules/*.md (agy, needs frontmatter trigger:) + <project>/AGENTS.md (dsh + agy)
#   workflow: <project>/.agents/workflows/*.md (agy); subagent: <project>/.agents/agents/<name>.md (agy, Antigravity ≥2.0)
# Neither host reads <project>/.agents/<plugin>/ or <project>/.dsh/AGENTS.md.
install_project_agents() {
  host=$1; root="$PROJECT_DIR/.agents"
  results=""
  for skill in "$STAGE"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename -- "$skill")
    log "$host" "copy ${skill%/} -> $root/skills/$name"
    results="$results; $(copy_dir "${skill%/}" "$root/skills/$name")"
  done
  log "$host" "rules/*.md + .agents/AGENTS.md -> $root/rules/; commands/*.md -> $root/workflows/; agents/*.md -> $root/agents/"
  if [ "$DRY_RUN" = 1 ]; then results="$results; would write rules+workflows+agents"; else
    mkdir -p "$root/rules" "$root/workflows" "$root/agents"
    cp "$STAGE"/rules/*.md "$root/rules/"
    { printf -- '---\ntrigger: always_on\n---\n'; cat "$REPO_ROOT/.agents/AGENTS.md"; } > "$root/rules/mobile-dev.md"
    for f in "$STAGE"/commands/*.md; do [ -e "$f" ] && cp "$f" "$root/workflows/"; done
    for f in "$STAGE"/agents/*.md; do [ -e "$f" ] && cp "$f" "$root/agents/"; done
    results="$results; wrote rules+workflows+agents"
  fi
  log "$host" "mobile-plugin block in $PROJECT_DIR/AGENTS.md"
  results="$results; $(write_block "$PROJECT_DIR/AGENTS.md" "Mobile plugin (project scope): read .agents/rules/mobile-dev.md first; rules in .agents/rules/, skills in .agents/skills/.")"
  summarize "$results"
}

# ---- main ----
REMOTE=$(remote_url)

if [ -z "$SCOPE" ]; then
  if [ "$IS_TTY" != 1 ]; then
    echo "stdin is not a TTY — choose scope with --scope user|project" >&2
    exit 1
  fi
  choose "Which scope? user = global ($CLAUDE_DIR ...); project = target project dir" "user" "project" || exit 0
  SCOPE=$CHOICE
fi
if [ "$SCOPE" = project ]; then
  # Standing inside the plugin repo itself (running ./install.sh here) means no target project — ask for a path.
  if [ -d "$PROJECT_DIR" ] && [ "$(CDPATH= cd -- "$PROJECT_DIR" && pwd -P)" = "$REPO_ROOT" ]; then
    if [ "$IS_TTY" != 1 ]; then
      echo "inside the plugin repo — pass --project <path> or cd into the project and run $REPO_ROOT/install.sh" >&2
      exit 1
    fi
    printf 'Target project path (existing directory): ' > /dev/tty
    IFS= read -r PROJECT_DIR < /dev/tty
    case $PROJECT_DIR in "~"|"~/"*) PROJECT_DIR="$HOME_DIR${PROJECT_DIR#"~"}" ;; esac
  fi
  [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ] || { echo "error: project '$PROJECT_DIR' is not an existing directory" >&2; exit 1; }
  PROJECT_DIR=$(CDPATH= cd -- "$PROJECT_DIR" && pwd -P)
  [ "$PROJECT_DIR" != "$REPO_ROOT" ] || { echo "error: project is the plugin repo itself" >&2; exit 1; }
fi
if [ -z "$PACKS" ]; then
  if [ "$IS_TTY" != 1 ]; then
    echo "stdin is not a TTY — choose packs with --pack flutter,android,ios,rn" >&2
    exit 1
  fi
  pick --none "Which sub-plugins? (Up/Down move, Space toggles, a = all, Enter confirms, q = quit)" $ALL_PACKS || exit 0
  PACKS=$PICKED
  [ -n "$PACKS" ] || { echo "No pack selected — exiting."; exit 0; }
fi
build_stage
trap 'rm -rf "$STAGE_TMP"' EXIT
echo "scope: $SCOPE $([ "$SCOPE" = project ] && echo "(project = $PROJECT_DIR)") | pack: $PACKS"

echo "host   | detect  | result"
row() { printf '%-6s | %-7s | %s\n' "$1" "$2" "$3"; }

FOUND=""
for k in claude agy dsh; do present "$k" && FOUND="$FOUND $k"; done
if [ -z "$FOUND" ]; then
  for k in claude agy dsh; do row "$k" "no" "not detected"; done
  exit 1
fi

CHOSEN=$ONLY
if [ -z "$CHOSEN" ]; then
  for k in claude agy dsh; do
    if present "$k"; then row "$k" "yes" "ready to install"; else row "$k" "no" "-"; fi
  done
  if [ "$IS_TTY" != 1 ]; then
    echo "stdin is not a TTY — choose hosts with --only claude,agy,dsh" >&2
    exit 1
  fi
  pick "Which hosts? (Up/Down move, Space toggles, a = all, Enter confirms, q = quit)" $FOUND || exit 0
  CHOSEN=$PICKED
  if [ -z "$CHOSEN" ]; then echo "No host selected — exiting."; exit 0; fi
fi

FAILED=0
ROWS=""
PROJECT_AGENTS_BY=""
for k in $CHOSEN; do
  if ! present "$k"; then ROWS="$ROWS$k|no|not detected
"; continue; fi
  log "$k" "starting"
  case $k in
    claude) res=$(install_claude) ;;
    agy|dsh)
      if [ "$SCOPE" = project ]; then
        if [ -n "$PROJECT_AGENTS_BY" ]; then res="installed together with $PROJECT_AGENTS_BY"
        else res=$(install_project_agents "$k"); PROJECT_AGENTS_BY=$k; fi
      elif [ "$k" = agy ]; then res=$(install_agy)
      else res=$(install_dsh); fi ;;
  esac
  # install_* print logs and the result on stdout; take the last line as the result, print the rest.
  printf '%s\n' "$res" | sed '$d'
  ROWS="$ROWS$k|yes|$(printf '%s\n' "$res" | tail -n 1)
"
done

echo
echo "host   | detect  | result"
printf '%s' "$ROWS" | while IFS='|' read -r h dt rs; do
  [ -n "$h" ] || continue
  row "$h" "$dt" "$rs"
done
printf '%s' "$ROWS" | grep -q '|error' && FAILED=1 || true

echo "Restart each host's session to load the plugin. Antigravity/dsh are copies: after editing the repo rerun \`./install.sh --scope $SCOPE\`; Claude updates via marketplace."

[ "$FAILED" = 0 ] || exit 1
