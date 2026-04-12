#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/diego-gomez-olvera/android-tools-skill.git"
SKILL="android-tools-skill"
AGENTS_ALL="claude gemini android-studio codex"

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
install.sh — install android-tools-skill for your AI coding agent(s)

One-liner (run from your Android project root):
  curl -fsSL https://raw.githubusercontent.com/diego-gomez-olvera/android-tools-skill/main/install.sh | bash

Options:
  --all                     Install for all detected agents without prompting
  --agent=<id[,id,...]>     Install for specific agents only
                              IDs: claude, gemini, android-studio, codex
  --global                  Install user-wide (~/) instead of per-repo (./)
  --help                    Show this help
EOF
}

# ── Formatting ────────────────────────────────────────────────────────────────
bold()  { printf "\033[1m%s\033[0m" "$*"; }
green() { printf "\033[32m%s\033[0m" "$*"; }
yellow(){ printf "\033[33m%s\033[0m" "$*"; }
red()   { printf "\033[31m%s\033[0m" "$*"; }
dim()   { printf "\033[2m%s\033[0m" "$*"; }

step()  { printf "\n  $(bold '→') %s\n" "$*"; }
ok()    { printf "    $(green '✓') %s\n" "$*"; }
skip()  { printf "    $(yellow '~') %s\n" "$*"; }
fail()  { printf "    $(red '✗') %s\n" "$*" >&2; }

# ── Agent metadata ────────────────────────────────────────────────────────────
agent_label() {
  case "$1" in
    claude)         echo "Claude Code";;
    gemini)         echo "Gemini CLI";;
    android-studio) echo "Gemini for Android Studio";;
    codex)          echo "Codex";;
    *)              echo "$1";;
  esac
}

agent_path() {
  local id="$1" global="${2:-false}"
  case "$id" in
    claude)
      [[ "$global" == true ]] && echo "$HOME/.claude/skills/$SKILL" \
                               || echo ".claude/skills/$SKILL";;
    gemini)
      [[ "$global" == true ]] && echo "$HOME/.gemini/skills/$SKILL" \
                               || echo ".gemini/skills/$SKILL";;
    android-studio)
      [[ "$global" == true ]] && echo "" \
                               || echo ".skills/$SKILL";;
    codex)
      [[ "$global" == true ]] && echo "$HOME/.codex/skills/$SKILL" \
                               || echo ".codex/skills/$SKILL";;
  esac
}

# Returns 0 if the agent looks installed/configured in the current directory
agent_detected() {
  case "$1" in
    claude)         [[ -d ".claude" ]]          || command -v claude &>/dev/null;;
    gemini)         [[ -d ".gemini" ]]          || command -v gemini &>/dev/null;;
    android-studio) [[ -f "settings.gradle.kts" || -f "settings.gradle" || -d ".skills" ]];;
    codex)          [[ -d ".codex" ]]           || command -v codex  &>/dev/null;;
    *)              return 1;;
  esac
}

# ── Argument parsing ──────────────────────────────────────────────────────────
OPT_ALL=false
OPT_GLOBAL=false
OPT_AGENTS=""

for arg in "$@"; do
  case "$arg" in
    --all)       OPT_ALL=true;;
    --global)    OPT_GLOBAL=true;;
    --agent=*)   OPT_AGENTS="${arg#--agent=}";;
    --help|-h)   usage; exit 0;;
    *)           printf "Unknown option: %s\n" "$arg" >&2; exit 1;;
  esac
done

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  printf "%s\n" "$(red 'Error: git is required but not found in PATH.')" >&2
  exit 1
fi

# ── Banner (printed once) ─────────────────────────────────────────────────────
printf "\n$(bold 'android-tools-skill') — installer\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

# ── Determine target agents ───────────────────────────────────────────────────
TARGETS=""

if [[ -n "$OPT_AGENTS" ]]; then
  TARGETS="${OPT_AGENTS//,/ }"
  for id in $TARGETS; do
    [[ " $AGENTS_ALL " == *" $id "* ]] || {
      printf "Unknown agent ID: %s\nValid IDs: %s\n" "$id" "$AGENTS_ALL" >&2
      exit 1
    }
  done
elif [[ "$OPT_ALL" == true ]]; then
  TARGETS="$AGENTS_ALL"
else
  # Auto-detect
  DETECTED=""
  for id in $AGENTS_ALL; do
    agent_detected "$id" && DETECTED="$DETECTED $id" || true
  done
  DETECTED="${DETECTED# }"

  if [[ -z "$DETECTED" ]]; then
    printf "\nNo supported agents detected.\n"
    printf "%s\n\n" "$(dim 'Run with --agent=<id> to install manually.')"
    printf "  Supported IDs: %s\n\n" "$AGENTS_ALL"
    exit 1
  fi

  printf "\nDetected:\n"
  for id in $DETECTED; do
    printf "  • %s\n" "$(agent_label "$id")"
  done

  # When piped (curl | bash), stdin is the pipe — read the prompt answer from /dev/tty.
  # When running interactively, stdin IS the terminal, so /dev/stdin works just as well.
  TTY="/dev/tty"
  [[ -t 0 ]] && TTY="/dev/stdin"
  if [[ -e "$TTY" ]]; then
    printf "\nInstall for all detected agents? [Y/n] "
    read -r answer < "$TTY"
    [[ "$answer" =~ ^[Nn] ]] && { printf "Aborted.\n\n"; exit 0; }
  fi

  TARGETS="$DETECTED"
fi

# ── Install loop ──────────────────────────────────────────────────────────────
COUNT_OK=0
COUNT_SKIP=0
COUNT_FAIL=0

for id in $TARGETS; do
  label="$(agent_label "$id")"
  dest="$(agent_path "$id" "$OPT_GLOBAL")"

  step "$label"

  if [[ -z "$dest" ]]; then
    scope="$([[ "$OPT_GLOBAL" == true ]] && echo "global " || echo "")install"
    skip "No $scope path defined for $label — skipping"
    (( COUNT_SKIP++ )) || true
    continue
  fi

  if [[ -d "$dest/.git" ]]; then
    # Already a git repo — pull updates
    printf "    %s\n" "$(dim "Updating $dest")"
    pull_err=""
    if pull_err=$(git -C "$dest" pull --ff-only 2>&1); then
      git -C "$dest" sparse-checkout set --no-cone /SKILL.md /agents/ /references/ /README.md 2>/dev/null || true
      ok "Updated $(dim "($dest)")"
      (( COUNT_OK++ )) || true
    else
      skip "Could not fast-forward: ${pull_err:-unknown error} — leaving existing install intact$(dim " ($dest)")"
      (( COUNT_SKIP++ )) || true
    fi
  elif [[ -d "$dest" ]]; then
    skip "$dest exists but is not a git repo — skipping"
    (( COUNT_SKIP++ )) || true
  else
    printf "    %s\n" "$(dim "Cloning into $dest")"
    mkdir -p "$(dirname "$dest")"
    clone_err=""
    if clone_err=$(git clone --depth 1 --filter=blob:none --sparse "$REPO" "$dest" 2>&1); then
      git -C "$dest" sparse-checkout set --no-cone /SKILL.md /agents/ /references/ /README.md 2>/dev/null || true
      ok "Installed $(dim "($dest)")"
      (( COUNT_OK++ )) || true
    else
      fail "Clone failed: ${clone_err:-unknown error}"
      (( COUNT_FAIL++ )) || true
    fi
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
if (( COUNT_FAIL > 0 )); then
  msg="$(green "$COUNT_OK installed")"
  (( COUNT_SKIP > 0 )) && msg+=", $COUNT_SKIP skipped"
  msg+=", $(red "$COUNT_FAIL failed")"
  printf "%s\n\n" "$msg"
  exit 1
elif (( COUNT_OK == 0 )); then
  printf "%s\n\n" "$(yellow "Nothing installed") ($COUNT_SKIP skipped)"
else
  msg="$(green "$COUNT_OK installed")"
  (( COUNT_SKIP > 0 )) && msg+=", $COUNT_SKIP skipped"
  printf "%s\n\n" "$msg"
  printf "Verify prerequisites in your Android project root:\n"
  printf "  %s\n" "$(dim 'adb version          # Android SDK Platform Tools')"
  printf "  %s\n" "$(dim 'java --version        # JDK 17+ required')"
  printf "  %s\n\n" "$(dim './gradlew --version   # Gradle wrapper')"
fi
