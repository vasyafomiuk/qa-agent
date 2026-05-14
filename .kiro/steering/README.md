# QA Agent Steering — Map & Customization Guide

This directory configures a functional-testing agent that runs in Kiro. It is **modular by design**: each concern lives in its own file so you can edit, replace, or disable pieces without breaking the rest.

## File map

| File | Inclusion | Purpose |
| --- | --- | --- |
| `00-overview.md` | always | Entry point. What the agent is, how to start a session. |
| `01-principles.md` | always | Core principles + Human-in-the-Loop rules. |
| `02-testing-modes.md` | always | Mode selector: exploratory / smoke / scenarios. |
| `10-jira-integration.md` | manual | How to fetch test issues and write results back. |
| `11-playwright-usage.md` | manual | Browser automation rules and tool inventory. |
| `12-secrets-management.md` | manual | Secrets policy, storage, retrieval, redaction. |
| `13-test-reporting.md` | manual | Report layout, artifacts, Jira comment template. |
| `14-best-practices.md` | manual | Test-engineering norms (independence, evidence, flake handling). |
| `20-mode-exploratory.md` | manual | Charter-driven exploratory testing workflow. |
| `21-mode-smoke.md` | manual | Smoke-pass workflow against critical paths. |
| `22-mode-scenarios.md` | manual | BDD scenario execution (Jira or local `.feature`). |
| `30-bdd-format.md` | fileMatch `*.feature` | Gherkin parsing rules and step mapping. |
| `40-memory-skill.md` | always | How the agent recognizes "remember X" / "forget X" and writes to `99-memory.md`. |
| `99-memory.md` | always | The agent's persistent memory for this project (preferences, corrections, routes, facts, people). Loads last so memory wins on conflict. |

Files marked **always** load on every session. **Manual** files load when referenced (e.g., when the orchestrator routes to that mode). **fileMatch** files load automatically when the agent opens a matching file.

## Customizing

- **Change tooling**: edit `11-playwright-usage.md` to point at a different browser MCP (Selenium MCP, Puppeteer, etc.). The agent only depends on the tool *contract* documented in that file.
- **Change tracker**: replace `10-jira-integration.md` with `10-linear-integration.md` (or similar). Update `02-testing-modes.md` to reference the new file.
- **Change secret backend**: edit `12-secrets-management.md`. Default is `.env` + OS env vars; swap for 1Password CLI, AWS Secrets Manager, or Vault.
- **Add a mode**: drop a `23-mode-<name>.md` file and add it to `02-testing-modes.md`. The mode selector will pick it up.
- **Project-specific overrides**: create `99-project-overrides.md` (always-inclusion). Anything there wins over earlier files.
- **Persistent memory**: tell the agent *"remember X"* or *"forget X"* and it updates `99-memory.md`. See `40-memory-skill.md` for the trigger phrases and write workflow.

## Companion directories

- `.kiro/config/` — sample config files (targets, environments). Copy `.example` files and edit.
- `.kiro/reports/` — generated test reports land here.
- `.kiro/artifacts/` — screenshots, traces, console logs.
- `scenarios/` — local `.feature` files for offline scenario execution.

## What this steering deliberately does NOT do

- It does not execute destructive production actions without explicit human approval (see `01-principles.md`).
- It does not commit secrets to disk in any form other than the gitignored `.env`.
- It does not transition Jira issue statuses unless explicitly asked. It only adds comments by default.
