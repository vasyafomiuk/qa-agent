#!/usr/bin/env bash
# setup.sh — bootstrap the QA agent workspace.
# Idempotent: safe to re-run. Will not overwrite your edited config files.

set -euo pipefail

# ─── Style helpers ──────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ -n "${TERM:-}" && "${TERM}" != "dumb" ]]; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"
  GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"; RED="$(tput setaf 1)"; BLUE="$(tput setaf 4)"
  RESET="$(tput sgr0)"
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; BLUE=""; RESET=""
fi

ok()   { printf "%s✓%s %s\n" "$GREEN"  "$RESET" "$*"; }
warn() { printf "%s!%s %s\n" "$YELLOW" "$RESET" "$*"; }
err()  { printf "%s✗%s %s\n" "$RED"    "$RESET" "$*" >&2; }
step() { printf "\n%s%s%s\n"  "$BOLD"  "$*"     "$RESET"; }

# ─── Resolve repo root regardless of invocation path ────────────────────────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

step "QA Agent setup"
printf "%sworking in:%s %s\n" "$DIM" "$RESET" "$ROOT"

# ─── 1/4  Prerequisite check ────────────────────────────────────────────────
step "1/4  Prerequisite check"
required=(git)
optional=(gh)
for cmd in "${required[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd ($(command -v "$cmd"))"
  else
    err "$cmd not found — required"
    exit 1
  fi
done
for cmd in "${optional[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd present"
  else
    warn "$cmd not found — optional (used for the GitHub publish flow)"
  fi
done

# ─── 2/4  Working directories ───────────────────────────────────────────────
step "2/4  Creating gitignored working directories"
for d in .kiro/reports .kiro/artifacts .kiro/config/storage-states; do
  if [[ -d "$d" ]]; then
    ok "$d (exists)"
  else
    mkdir -p "$d"
    ok "$d (created)"
  fi
done

# ─── 3/4  Config from templates ─────────────────────────────────────────────
step "3/4  Copying config templates (will not overwrite)"
pairs=(
  ".kiro/config/secrets.example.env|.kiro/config/.env|600"
  ".kiro/config/targets.example.yml|.kiro/config/targets.yml|644"
  ".kiro/config/smoke.example.yml|.kiro/config/smoke.yml|644"
)
for pair in "${pairs[@]}"; do
  IFS='|' read -r src dst mode <<<"$pair"
  if [[ ! -f "$src" ]]; then
    warn "template missing: $src — skipping"
    continue
  fi
  if [[ -f "$dst" ]]; then
    ok "$dst (kept — your edits are safe)"
  else
    cp "$src" "$dst"
    chmod "$mode" "$dst" 2>/dev/null || true
    ok "$dst (created, chmod $mode)"
  fi
done

# ─── 4/4  Safety: confirm .env is gitignored ────────────────────────────────
step "4/4  Safety check — .env must be gitignored"
sentinel=".kiro/config/.env"
if [[ -f "$sentinel" ]]; then
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$ROOT" check-ignore -q "$sentinel"; then
      ok "$sentinel is gitignored"
    else
      err "$sentinel is NOT gitignored. STOP — fix .gitignore before adding any secrets."
      exit 1
    fi
  else
    warn "not a git repo yet — skipped gitignore check"
  fi
fi

# ─── Summary ────────────────────────────────────────────────────────────────
step "Setup complete."
cat <<EOF

${BOLD}Next steps:${RESET}
  ${BLUE}1.${RESET} Edit ${BOLD}.kiro/config/.env${RESET} and fill in:
       • JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
       • QA_<env>_<role>_EMAIL and QA_<env>_<role>_PASSWORD for your test users
  ${BLUE}2.${RESET} Adjust ${BOLD}.kiro/config/targets.yml${RESET} and ${BOLD}smoke.yml${RESET} to match your app.
  ${BLUE}3.${RESET} ${DIM}(If not already configured in Kiro)${RESET} ensure these MCP servers are available:
       • A Jira MCP server (read scenarios + post comments)
       • A Playwright MCP server (drive the browser)
     The agent verifies capability on first use; no install step needed here.
  ${BLUE}4.${RESET} Open this directory in Kiro and try a session:
       "Run ${BOLD}scenarios/login.feature${RESET} against staging."
       "Run ${BOLD}smoke${RESET} on staging."
       "Explore the ${BOLD}checkout${RESET} flow for 30 minutes on staging."

${DIM}Re-run this script anytime — it's idempotent and won't clobber your edits.${RESET}
EOF
