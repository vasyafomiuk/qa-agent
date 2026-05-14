---
inclusion: manual
---

# Mode: Scenario Execution

Scenario mode runs **named BDD scenarios** end-to-end, captures evidence per step, and produces a report. Scenarios come from one of two sources, never mixed in a single run:

- **Jira**: one or more issue keys (see `10-jira-integration.md`).
- **Local file**: a `.feature` file in `scenarios/` (see `30-bdd-format.md`).

## Inputs

The agent confirms before starting:

1. **Source**: Jira keys or a `.feature` path (or a directory of them).
2. **Target environment**: URL + auth profile.
3. **Writeback authorization**: post Jira comments? (Default: no.)
4. **Scope filter**: tags to include or exclude (e.g., `@smoke`, `@regression`, `not @manual`).

If multiple scenarios are queued, the agent **lists them** in chat and waits for "yes / edit / no" before starting. Never run a batch silently.

## Source: Jira

1. Resolve each issue key via Jira MCP (`10-jira-integration.md`).
2. Extract BDD content per the priority order in that file.
3. Parse with rules from `30-bdd-format.md`.
4. If a key resolves to multiple scenarios (e.g., a feature with several `Scenario:` blocks), keep them grouped under that key in the report.

## Source: local `.feature`

1. Read the file. The file-match rule auto-loads `30-bdd-format.md`.
2. List the scenarios discovered. Confirm the list with the user.
3. Run in file order unless the user asks for tag filtering.

## Execution flow per scenario

```
For each scenario:
  1. Open a fresh browser context.
  2. Run Background steps if present.
  3. For each step:
     a. Announce the step.
     b. Map the step to the planned action (`30-bdd-format.md`).
     c. Capture baseline screenshot if it's the first step of the scenario.
     d. Execute the action via Playwright MCP (`11-playwright-usage.md`).
     e. Verify the postcondition.
     f. Capture evidence on every `Then` step.
  4. Close the browser context.
  5. Append result to the report.
```

Step-level failure rules:

- A failure within a scenario **stops that scenario** (don't run subsequent steps blindly).
- Other scenarios in the batch **continue**.
- Retries: see `14-best-practices.md` (one whole-scenario retry on transient failures).

## Step-to-action mapping

For each step, the agent emits a short plan **before** acting:

```
Step: When the user enters "qa@example.com" in the Email field
Plan: locator('role=textbox[name="Email"]').fill('qa@example.com')
```

If the agent cannot find a clean mapping, it stops and asks: "I see the step says 'When they configure 2FA' — there are three ways to interpret this. Which do you mean?" — list the options.

## Scenario Outlines

For `Scenario Outline` with `Examples`, each example row is a **separate scenario** in the report. Use the row values in the headline: "Login with admin@... → PASS".

## Tags

Honor these tag conventions:

- `@smoke` — include in smoke runs.
- `@regression` — full regression suite.
- `@manual` — skip in automated runs.
- `@wip` — skip unless `--include-wip` was requested.
- `@flaky` — run, but never auto-retry; surface every observation to the human.
- `@destructive` — pause for explicit human approval before running. **Even in non-prod.**
- `@prod-safe` — explicitly safe to run in production. Without this tag, refuse production runs.

Unknown tags are recorded but do not change behavior.

## Output

Per-scenario report sections in the format defined in `13-test-reporting.md`. The summary table aggregates across all scenarios in the run.

## Jira writeback flow (if authorized)

For each Jira-sourced scenario:

1. Render the comment using the template in `10-jira-integration.md`.
2. Show the rendered comment in chat.
3. Wait for explicit "yes / no / edit" per issue.
4. Post on "yes", record the comment URL in the report.

Do **not** batch-post a dozen comments behind one "yes". The user must approve each (or explicitly say "post all").

## Failure modes specific to scenario mode

- **Scenario references a missing feature** (e.g., the page doesn't exist): BLOCKED — possible product change. Surface to the human.
- **Step ambiguous**: stop the scenario, ask the human to clarify, do not guess.
- **Background failed**: every dependent scenario in the file is BLOCKED. Report once at the file level.
- **`.feature` file has parse errors** (`30-bdd-format.md`): BLOCKED — do not attempt to "fix" the file.

## HITL checkpoints (scenario mode)

- Confirm the scenario list before the batch starts.
- Approve any `@destructive` scenario individually.
- Approve any production-targeted scenario individually (must have `@prod-safe`).
- Approve each Jira comment before posting.
- Classify any `NEEDS-HUMAN` result before the report is finalized.
