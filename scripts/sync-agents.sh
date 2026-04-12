#!/usr/bin/env bash
# sync-agents.sh — verify that agent configuration files are in sync with the
# skill. Focuses on .github/copilot-instructions.md, which is a static file
# that must be updated manually when scripts or tool mappings change.
#
# Run this after adding scripts or updating the SKILL.md tool mapping table.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

red()    { echo -e "\033[31m$*\033[0m"; }
green()  { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

error()   { red "  ERROR: $*";   ((ERRORS++))   || true; }
warning() { yellow "  WARN:  $*"; ((WARNINGS++)) || true; }
ok()      { green "  OK:    $*"; }

COPILOT="$SKILL_DIR/.github/copilot-instructions.md"
SKILL_MD="$SKILL_DIR/SKILL.md"

echo "Syncing agents at: $SKILL_DIR"
echo "========================================"

# ── 1. copilot-instructions.md exists ────────────────────────────────────────
echo ""
echo "1. .github/copilot-instructions.md present"

if [[ ! -f "$COPILOT" ]]; then
    error ".github/copilot-instructions.md missing — run: install.sh --agent=copilot"
    echo ""
    echo "========================================"
    red "Failed: $ERRORS error(s). Fix errors before committing."
    exit 1
fi
ok ".github/copilot-instructions.md exists"

# ── 2. Scripts listed in copilot-instructions.md exist in skill-scripts/ ─────
echo ""
echo "2. Scripts in copilot-instructions.md → exist in skill-scripts/"

while IFS= read -r script; do
    if [[ -f "$SKILL_DIR/skill-scripts/$script" ]]; then
        ok "$script"
    else
        error "$script listed in copilot-instructions.md but not found in skill-scripts/"
    fi
done < <(grep -oE 'skill-scripts/[a-zA-Z0-9_-]+\.(sh|py)' "$COPILOT" | sed 's|skill-scripts/||' | sort -u)

# ── 3. Public scripts in skill-scripts/ are listed in copilot-instructions.md ─
echo ""
echo "3. skill-scripts/ public scripts → listed in copilot-instructions.md"

while IFS= read -r script; do
    name=$(basename "$script")
    if grep -q "$name" "$COPILOT"; then
        ok "$name"
    else
        warning "$name not listed in copilot-instructions.md"
    fi
done < <(find "$SKILL_DIR/skill-scripts" -maxdepth 1 \( -name "*.sh" -o -name "*.py" \) | sort)

# ── 4. Tool names from SKILL.md mapping table appear in copilot-instructions.md
echo ""
echo "4. SKILL.md tool names → present in copilot-instructions.md"

while IFS= read -r tool; do
    if grep -q "$tool" "$COPILOT"; then
        ok "$tool"
    else
        warning "'$tool' in SKILL.md mapping table but missing from copilot-instructions.md"
    fi
done < <(grep -oE '^\| `[a-z_]+`' "$SKILL_MD" | grep -oE '[a-z_]{3,}' | sort -u)

# ── 5. Public scripts in skill-scripts/ are listed in README.md ──────────────
echo ""
echo "5. skill-scripts/ public scripts → listed in README.md"

README="$SKILL_DIR/README.md"
while IFS= read -r script; do
    name=$(basename "$script")
    [[ "$name" == "internal" ]] && continue  # skip subdirectory entry
    if grep -q "$name" "$README"; then
        ok "$name"
    else
        warning "$name not listed in README.md"
    fi
done < <(find "$SKILL_DIR/skill-scripts" -maxdepth 1 \( -name "*.sh" -o -name "*.py" \) | sort)

# ── 6. Tool names from SKILL.md appear in README.md ──────────────────────────
echo ""
echo "6. SKILL.md tool names → present in README.md"

while IFS= read -r tool; do
    if grep -q "$tool" "$README"; then
        ok "$tool"
    else
        warning "'$tool' in SKILL.md mapping table but missing from README.md"
    fi
done < <(grep -oE '^\| `[a-z_]+`' "$SKILL_MD" | grep -oE '[a-z_]{3,}' | sort -u)

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
if (( ERRORS == 0 && WARNINGS == 0 )); then
    green "All agents in sync."
elif (( ERRORS == 0 )); then
    yellow "In sync with $WARNINGS warning(s) — update copilot-instructions.md."
else
    red "Out of sync: $ERRORS error(s), $WARNINGS warning(s)."
    exit 1
fi
