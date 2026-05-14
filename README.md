# QA Agent — Kiro Steering for Functional Testing

A modular Kiro steering configuration that turns Kiro into a functional QA agent. The agent reads BDD scenarios from Jira or local `.feature` files, drives a real browser via Playwright MCP, captures evidence, and writes a report (with optional Jira writeback). A human stays in the loop on every important decision.

## Prerequisites

The agent uses two MCP servers via Kiro. If you've already configured them for another project, **you're done — skip this section**. To check, open Kiro's MCP settings.

- A **Jira MCP** server — read issues, search by JQL, post comments.
- A **Playwright MCP** server — drive the browser.

The steering doesn't hard-code tool names. It verifies the required capability on first use and surfaces a clear error if a server is missing or mis-configured.

## Quick start

The setup script installs into **`~/.kiro/`** (user-global). After install, the QA agent's steering is loaded by **every** Kiro project on this machine — you don't need to clone or re-install per project.

1. **Run the setup script** (idempotent — safe to re-run after `git pull`):
   ```sh
   ./setup.sh           # install to ~/.kiro/
   ./setup.sh --dry-run # preview without writing
   ./setup.sh --force   # overwrite locally-modified steering files
   ```
   Lands the steering at `~/.kiro/steering/`, config templates at `~/.kiro/config/`, example scenarios at `~/.kiro/scenarios/`, and creates `~/.kiro/{reports,artifacts}/`. Never overwrites your edits to `.env`, `targets.yml`, or `smoke.yml`.
2. **Fill in `~/.kiro/config/.env`** with your Jira token and test-user credentials. The script `chmod 600`'s the file on creation.
3. **Adjust** `~/.kiro/config/targets.yml` and `~/.kiro/config/smoke.yml` to match your app.
4. **Open any project in Kiro.** The QA agent steering is loaded automatically — no per-project setup needed.
5. **Ask the agent to test something**, for example:
   - `Run smoke on staging.`
   - `Run scenarios/login.feature against staging.`
   - `Explore the checkout flow for 30 minutes on staging.`
   - `Run QA-123 against staging and post results to Jira when done.`
6. **Teach it.** Say *"remember the admin panel is at /admin/v2"* or *"remember to skip @flaky scenarios in smoke runs"* and the agent will write it into `~/.kiro/steering/99-memory.md` (always-loaded). Say *"forget X"* to remove it. See [`40-memory-skill.md`](.kiro/steering/40-memory-skill.md) for the trigger phrases and write workflow.

### Project-specific overrides

The global steering is the default. If a specific project needs different rules, drop a `.kiro/steering/99-project-overrides.md` in that project's root — Kiro merges it with the global steering, and your overrides win.

### Updating

When this repo gets new commits, `git pull` then `./setup.sh` again. Files that match source are reported as `(current)`; files you've edited locally are reported as `(kept)` unless you pass `--force`.

## Three testing modes

| Mode | What it does | Source of truth |
| --- | --- | --- |
| **Exploratory** | Charter-driven session, agent surfaces observations | Human-written charter |
| **Smoke** | Quick critical-path check, stops on first failure | `.kiro/config/smoke.yml` |
| **Scenarios** | Run named BDD scenarios end-to-end | Jira issues or `*.feature` files |

The agent picks the mode from your request. If it can't, it asks.

## Human-in-the-Loop

The agent **always pauses** before:
- Running against production.
- Doing anything destructive (delete, payment, send email).
- Posting comments back to Jira.
- Closing a Jira issue or transitioning status (it doesn't — the human does).
- Marking a flaky test as a clean pass.
- Going off-charter in exploratory mode.

See [`.kiro/steering/01-principles.md`](.kiro/steering/01-principles.md) for the full list.

## Directory layout

**This repo is the source.** Run `./setup.sh` to install into `~/.kiro/`.

```
qa-agent/                     ← this repo (source of truth)
├── setup.sh                  ← installs to ~/.kiro/
├── .kiro/
│   ├── steering/             ← steering files (the agent's instructions)
│   │   ├── README.md
│   │   ├── 00-overview.md
│   │   ├── 01-principles.md
│   │   ├── 02-testing-modes.md
│   │   ├── 10-jira-integration.md
│   │   ├── 11-playwright-usage.md
│   │   ├── 12-secrets-management.md
│   │   ├── 13-test-reporting.md
│   │   ├── 14-best-practices.md
│   │   ├── 20-mode-exploratory.md
│   │   ├── 21-mode-smoke.md
│   │   ├── 22-mode-scenarios.md
│   │   ├── 30-bdd-format.md
│   │   ├── 40-memory-skill.md
│   │   └── 99-memory.md
│   └── config/               ← *.example.* templates only
└── scenarios/                ← example .feature files
```

After running `./setup.sh`:

```
~/.kiro/                      ← user-global Kiro home (install target)
├── steering/                 ← all qa-agent steering, loaded everywhere
├── config/
│   ├── .env                  ← chmod 600, your secrets (never committed anywhere)
│   ├── targets.yml           ← your environments
│   ├── smoke.yml             ← your smoke set
│   └── *.example.*           ← refreshed from source on each install
├── scenarios/                ← .feature files
├── reports/                  ← generated reports
└── artifacts/                ← screenshots, logs
```

## Customizing

Each steering file owns one concern. Edit just that file to change behavior:

- Different tracker than Jira? Replace `10-jira-integration.md`.
- Different browser driver? Replace `11-playwright-usage.md`.
- Different secret backend? Edit `12-secrets-management.md`.
- Add a new mode? Drop `23-mode-<name>.md` and reference it from `02-testing-modes.md`.
- Project-specific overrides? Create `99-project-overrides.md` (always-inclusion) — anything there wins.

The full customization guide is in [`.kiro/steering/README.md`](.kiro/steering/README.md).

## Safety summary

- Secrets live in `~/.kiro/config/.env` (chmod 600 by `setup.sh`) or your chosen backend; **never** in chat history. The agent redacts secrets in every output channel.
- `~/.kiro/` is outside any git repo, so `.env` cannot be accidentally committed by being in a tracked directory. The repo's own `.kiro/config/` only contains `.example.*` templates.
- Production targets require explicit per-session approval; only scenarios tagged `@prod-safe` are eligible.
- Jira writeback is opt-in per session and approved comment-by-comment.
- Destructive scenarios (tagged `@destructive`) require explicit human approval even on staging.
