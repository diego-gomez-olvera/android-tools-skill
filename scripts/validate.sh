#!/usr/bin/env bash
# validate.sh — checks android-tools-skill structure and internal links
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

echo "Validating android-tools-skill at: $SKILL_DIR"
echo "========================================"

# ── Required files ──────────────────────────────────────────────────────────
echo ""
echo "1. Required files"

required_files=(
  "SKILL.md"
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  "agents/openai.yaml"
  "references/adb-device.md"
  "references/adb-logging.md"
  "references/gradle-build.md"
  "references/gradle-project.md"
  "references/static-analysis.md"
  "references/testing.md"
  "references/deploy.md"
  "references/version-lookup.md"
  "references/code-search.md"
  "references/profiling.md"
  "references/app-size.md"
)

for f in "${required_files[@]}"; do
  if [[ -f "$SKILL_DIR/$f" ]]; then
    ok "$f"
  else
    error "Missing: $f"
  fi
done

# ── SKILL.md front-matter ───────────────────────────────────────────────────
echo ""
echo "2. SKILL.md front-matter"

if grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
  ok "name field present"
else
  error "SKILL.md missing 'name:' in front-matter"
fi

if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
  ok "description field present"
else
  error "SKILL.md missing 'description:' in front-matter"
fi

# ── SKILL.md size ───────────────────────────────────────────────────────────
echo ""
echo "3. SKILL.md size"

line_count=$(wc -l < "$SKILL_DIR/SKILL.md")
if (( line_count <= 500 )); then
  ok "SKILL.md is $line_count lines (≤500)"
else
  warning "SKILL.md is $line_count lines (recommended ≤500)"
fi

# ── Internal links (all .md files) ───────────────────────────────────────────
echo ""
echo "4. Internal links in .md files"

check_links_in_file() {
  local src="$1" src_name re
  src_name=$(basename "$src")
  re='\(references/([a-zA-Z0-9_-]+\.md)(#[^)]+)?\)'
  while IFS= read -r line; do
    while [[ "$line" =~ $re ]]; do
      ref="${BASH_REMATCH[1]}"
      fragment="${BASH_REMATCH[2]:-}"
      line="${line#*"(references/$ref${fragment})"}"
      if [[ -f "$SKILL_DIR/references/$ref" ]]; then
        ok "$src_name → references/$ref"
      else
        error "Broken link in $src_name: references/$ref not found"
      fi
    done
  done < "$src"
}

for md_file in "$SKILL_DIR"/*.md "$SKILL_DIR/references/"*.md; do
  [[ -f "$md_file" ]] && check_links_in_file "$md_file"
done

# ── Reference files link back or are listed ─────────────────────────────────
echo ""
echo "5. All reference files are linked from SKILL.md"

for ref_file in "$SKILL_DIR/references/"*.md; do
  name=$(basename "$ref_file")
  if grep -q "$name" "$SKILL_DIR/SKILL.md"; then
    ok "references/$name is linked"
  else
    warning "references/$name is NOT linked from SKILL.md"
  fi
done

# ── Agent pointer files ──────────────────────────────────────────────────────
echo ""
echo "6. Agent pointer files (CLAUDE.md, GEMINI.md → AGENTS.md)"

for pointer in "CLAUDE.md" "GEMINI.md"; do
  if grep -q "AGENTS.md" "$SKILL_DIR/$pointer"; then
    ok "$pointer references AGENTS.md"
  else
    error "$pointer does not reference AGENTS.md"
  fi
done

# ── agents/openai.yaml ──────────────────────────────────────────────────────
echo ""
echo "7. agents/openai.yaml"

if grep -q "display_name" "$SKILL_DIR/agents/openai.yaml"; then
  ok "display_name present"
else
  error "agents/openai.yaml missing 'display_name'"
fi

if grep -q "default_prompt" "$SKILL_DIR/agents/openai.yaml"; then
  ok "default_prompt present"
else
  error "agents/openai.yaml missing 'default_prompt'"
fi

# ── Reference file sizes ────────────────────────────────────────────────────
echo ""
echo "8. Reference file sizes"

for ref_file in "$SKILL_DIR/references/"*.md; do
  name=$(basename "$ref_file")
  lines=$(wc -l < "$ref_file")
  if (( lines <= 500 )); then
    ok "references/$name: $lines lines"
  else
    warning "references/$name: $lines lines (recommended ≤500)"
  fi
done

# ── install.sh executable ────────────────────────────────────────────────────
echo ""
echo "9. install.sh is executable"

if [[ -x "$SKILL_DIR/install.sh" ]]; then
  ok "install.sh is executable"
else
  error "install.sh is not executable (run: chmod +x install.sh)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
if (( ERRORS == 0 && WARNINGS == 0 )); then
  green "All checks passed. Skill is valid."
elif (( ERRORS == 0 )); then
  yellow "Passed with $WARNINGS warning(s). Review warnings before publishing."
else
  red "Failed: $ERRORS error(s), $WARNINGS warning(s). Fix errors before committing."
  exit 1
fi
