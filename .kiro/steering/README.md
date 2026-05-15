# Steering — Map & Customization

Each file owns one concern. Edit just that file to change behavior.

| File | Inclusion | Purpose |
| --- | --- | --- |
| `00-core.md` | always | Overview, HITL rules, mode picker, output discipline. |
| `10-integrations.md` | manual | Jira MCP (read + comment writeback) and Playwright MCP (browser). |
| `20-modes.md` | manual | Exploratory, smoke, and scenario execution. |
| `30-secrets.md` | manual | Secret storage, naming, redaction, MFA, production rules. |
| `40-reporting.md` | manual | Report format, status taxonomy, evidence rules, test-engineering practices. |
| `50-bdd.md` | fileMatch `*.feature` | Gherkin parsing and step → action mapping. |
| `99-memory.md` | always | Persistent memory: skill rules + the store the agent appends to. |

**Always-loaded** core: `00-core.md` + `99-memory.md`. The rest load on demand (manual / fileMatch).

## Customizing

- **Different tracker than Jira?** Edit the Jira section of `10-integrations.md`.
- **Different browser driver?** Edit the Playwright section of `10-integrations.md`.
- **Different secret backend?** Edit `30-secrets.md`.
- **Project-specific rules?** Create `99-project-overrides.md` (always-inclusion). Loads after `99-memory.md` so it wins on conflict.
- **Persistent memory?** Just tell the agent *"remember X"* or *"forget X"* — see `99-memory.md`.

## What this steering deliberately does NOT do

- Doesn't execute destructive production actions without explicit approval (see HITL in `00-core.md`).
- Doesn't commit secrets to any tracked file.
- Doesn't transition Jira issue statuses — only adds comments.
