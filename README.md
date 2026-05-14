# QA Agent — Kiro Steering for Functional Testing

A modular Kiro steering configuration that turns Kiro into a functional QA agent. The agent reads BDD scenarios from Jira or local `.feature` files, drives a real browser via Playwright MCP, captures evidence, and writes a report (with optional Jira writeback). A human stays in the loop on every important decision.

## Quick start

1. **Run the setup script** (idempotent — safe to re-run):
   ```sh
   ./setup.sh
   ```
   It creates `.kiro/reports/`, `.kiro/artifacts/`, `.kiro/config/storage-states/`, copies the `*.example.*` templates into their real names without clobbering edits, locks down `.env` with `chmod 600`, and verifies `.env` is gitignored.
2. **Fill in `.kiro/config/.env`** with your Jira token and test-user credentials. Never commit this file (already in `.gitignore`).
3. **Adjust** `.kiro/config/targets.yml` and `.kiro/config/smoke.yml` to match your app.
4. **Install MCP servers in Kiro** (one-time):
   - A Jira MCP server (for issue read + comment write).
   - A Playwright MCP server (for browser control).
5. **Open this directory in Kiro.** The steering files in `.kiro/steering/` load automatically.
6. **Ask the agent to test something**, for example:
   - `Run scenarios/login.feature against staging.`
   - `Run smoke on staging.`
   - `Explore the checkout flow for 30 minutes on staging.`
   - `Run QA-123 against staging and post results to Jira when done.`
7. **Teach it.** Say *"remember the admin panel is at /admin/v2"* or *"remember to skip @flaky scenarios in smoke runs"* and the agent will write it into [`.kiro/steering/99-memory.md`](.kiro/steering/99-memory.md) (always-loaded). Say *"forget X"* to remove it. See [`40-memory-skill.md`](.kiro/steering/40-memory-skill.md) for the full set of triggers and the write workflow.

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

```
qa-agent/
├── setup.sh              ← run this first
├── .kiro/
│   ├── steering/         ← steering files (the agent's instructions)
│   │   ├── README.md        ← map + how to customize
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
│   │   └── 30-bdd-format.md
│   ├── config/           ← copy *.example.* → real file, then edit
│   ├── reports/          ← generated test reports (gitignored)
│   └── artifacts/        ← screenshots, console + network logs (gitignored)
└── scenarios/            ← local .feature files
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

- Secrets are loaded from `.env` (gitignored) or your chosen backend; **never** from chat history. The agent redacts secrets in every output channel.
- Production targets require explicit per-session approval; only scenarios tagged `@prod-safe` are eligible.
- Jira writeback is opt-in per session and approved comment-by-comment.
- Destructive scenarios (tagged `@destructive`) require explicit human approval even on staging.
