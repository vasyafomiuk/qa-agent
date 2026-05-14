#!/usr/bin/env bash
# setup.sh — install the QA agent into ~/.kiro (user-global Kiro home).
#
# This makes the steering, configs, and example scenarios available to
# every Kiro project on this machine. The repo itself is the source of
# truth; re-run this script to refresh ~/.kiro after pulling updates.
#
# Idempotent. Will not overwrite edited config files. Will not overwrite
# steering files that differ from source unless --force.

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
info() { printf "%s%s%s\n"    "$DIM"   "$*"     "$RESET"; }

# ─── Flags ──────────────────────────────────────────────────────────────────
FORCE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      cat <<'EOF'
Usage: ./setup.sh [--force] [--dry-run]

Installs the QA agent into ~/.kiro/ — the user-global Kiro home, loaded
by every Kiro project on this machine.

Layout after install:
  ~/.kiro/steering/   steering files (loaded automatically by Kiro)
  ~/.kiro/config/     .env, targets.yml, smoke.yml (+ .example.* templates)
  ~/.kiro/scenarios/  example .feature files
  ~/.kiro/reports/    generated test reports
  ~/.kiro/artifacts/  screenshots, console + network logs

Flags:
  --force    Overwrite existing steering files even if they differ from
             source. Real configs (.env, edited targets/smoke) are never
             touched by this flag.
  --dry-run  Show what would happen without writing.
EOF
      exit 0
      ;;
    *) err "Unknown flag: $arg (use --help)"; exit 1 ;;
  esac
done

# ─── Paths ──────────────────────────────────────────────────────────────────
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.kiro"

if [[ ! -d "$SRC/.kiro/steering" ]]; then
  err "Source not found: $SRC/.kiro/steering. Run from the repo root."
  exit 1
fi

step "QA Agent — install to ~/.kiro"
info "source:      $SRC"
info "destination: $DEST"
$DRY_RUN && warn "DRY RUN — no files will be written"
$FORCE && warn "FORCE — existing steering files will be overwritten"

# ─── 1/4  Destination directories ───────────────────────────────────────────
step "1/4  Creating $DEST/{steering,config,scenarios,reports,artifacts}"
for d in steering config config/storage-states scenarios reports artifacts; do
  if [[ -d "$DEST/$d" ]]; then
    ok "$d (exists)"
  elif $DRY_RUN; then
    info "would create $d"
  else
    mkdir -p "$DEST/$d" && ok "$d (created)"
  fi
done

# ─── 2/4  Steering files ────────────────────────────────────────────────────
step "2/4  Installing steering → $DEST/steering/"
new=0; updated=0; current=0; kept=0
shopt -s nullglob
for src_file in "$SRC/.kiro/steering"/*.md; do
  name="$(basename "$src_file")"
  dst="$DEST/steering/$name"
  if [[ ! -f "$dst" ]]; then
    if $DRY_RUN; then info "would install $name"
    else cp "$src_file" "$dst" && ok "$name (installed)"
    fi
    new=$((new+1))
  elif cmp -s "$src_file" "$dst"; then
    ok "$name (current)"
    current=$((current+1))
  elif $FORCE; then
    if $DRY_RUN; then info "would overwrite $name"
    else cp "$src_file" "$dst" && ok "$name (overwritten)"
    fi
    updated=$((updated+1))
  else
    warn "$name differs from source — kept local copy. Diff: diff '$src_file' '$dst'"
    kept=$((kept+1))
  fi
done
info "summary: $new new, $updated updated, $current already current, $kept locally-modified (use --force to overwrite)"

# ─── 3/4  Config templates ──────────────────────────────────────────────────
step "3/4  Installing config templates → $DEST/config/"
# Pairs: src_relative_to_repo | dst_absolute | mode | overwrite_policy
#   policy: skip-if-exists (real configs)
#   policy: refresh         (example templates — always update unless dry-run)
pairs=(
  ".kiro/config/secrets.example.env|$DEST/config/secrets.example.env|644|refresh"
  ".kiro/config/targets.example.yml|$DEST/config/targets.example.yml|644|refresh"
  ".kiro/config/smoke.example.yml|$DEST/config/smoke.example.yml|644|refresh"
  ".kiro/config/secrets.example.env|$DEST/config/.env|600|skip-if-exists"
  ".kiro/config/targets.example.yml|$DEST/config/targets.yml|644|skip-if-exists"
  ".kiro/config/smoke.example.yml|$DEST/config/smoke.yml|644|skip-if-exists"
)
for pair in "${pairs[@]}"; do
  IFS='|' read -r src_rel dst mode policy <<<"$pair"
  src="$SRC/$src_rel"
  base="${dst##*/}"
  if [[ ! -f "$src" ]]; then warn "template missing: $src_rel — skipping"; continue; fi

  case "$policy" in
    skip-if-exists)
      if [[ -f "$dst" ]]; then
        ok "$base (kept — your edits are safe)"
      elif $DRY_RUN; then
        info "would create $base"
      else
        cp "$src" "$dst" && chmod "$mode" "$dst" 2>/dev/null || true
        ok "$base (created, chmod $mode)"
      fi
      ;;
    refresh)
      if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        ok "$base (current)"
      elif $DRY_RUN; then
        info "would refresh $base"
      else
        cp "$src" "$dst" && chmod "$mode" "$dst" 2>/dev/null || true
        ok "$base (refreshed)"
      fi
      ;;
  esac
done

# ─── 4/4  Example scenarios ─────────────────────────────────────────────────
step "4/4  Installing example scenarios → $DEST/scenarios/"
for src_file in "$SRC/scenarios"/*.feature; do
  [[ -f "$src_file" ]] || continue
  name="$(basename "$src_file")"
  dst="$DEST/scenarios/$name"
  if [[ -f "$dst" ]]; then
    ok "$name (kept)"
  elif $DRY_RUN; then
    info "would install $name"
  else
    cp "$src_file" "$dst" && ok "$name (installed)"
  fi
done

# ─── Safety: chmod .env if it exists ────────────────────────────────────────
if [[ -f "$DEST/config/.env" ]] && ! $DRY_RUN; then
  chmod 600 "$DEST/config/.env" 2>/dev/null || true
fi

# ─── Summary & next steps ───────────────────────────────────────────────────
step "Done."
cat <<EOF

${BOLD}Where things landed:${RESET}
  ${BLUE}Steering${RESET}    $DEST/steering/      (loaded by every Kiro session)
  ${BLUE}Config${RESET}      $DEST/config/        (.env, targets.yml, smoke.yml)
  ${BLUE}Scenarios${RESET}   $DEST/scenarios/     (.feature files)
  ${BLUE}Reports${RESET}     $DEST/reports/       (generated)
  ${BLUE}Artifacts${RESET}   $DEST/artifacts/     (screenshots, logs)

${BOLD}Next steps:${RESET}
  ${BLUE}1.${RESET} Edit ${BOLD}$DEST/config/.env${RESET} and fill in:
       • JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
       • QA_<env>_<role>_EMAIL and QA_<env>_<role>_PASSWORD for your test users
  ${BLUE}2.${RESET} Adjust ${BOLD}$DEST/config/targets.yml${RESET} and ${BOLD}smoke.yml${RESET} to match your app.
  ${BLUE}3.${RESET} ${DIM}(If not already configured in Kiro)${RESET} ensure a Jira MCP and a Playwright MCP are available.
  ${BLUE}4.${RESET} Open ${BOLD}any${RESET} project in Kiro — the QA agent steering is now loaded globally.
       Try:
         "Run smoke on staging."
         "Run scenarios/login.feature against staging."
         "Explore the checkout flow for 30 minutes on staging."

${BOLD}Project-specific overrides:${RESET}
  Drop a ${BOLD}.kiro/steering/99-project-overrides.md${RESET} in any project root to
  override or extend the global steering for just that project.

${DIM}Re-run this script after pulling updates from the qa-agent repo —
it's idempotent. Use --force to overwrite locally-modified steering files;
--dry-run to preview.${RESET}
EOF
