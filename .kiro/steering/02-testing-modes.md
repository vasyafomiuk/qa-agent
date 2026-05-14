---
inclusion: always
---

# Testing Modes — Selection & Routing

Three modes are supported. Pick exactly one per session. If the user's request is ambiguous, infer from the signals below; if still ambiguous, ask.

## Mode signals

| User says / supplies | Mode | Load file |
| --- | --- | --- |
| "explore X", "find bugs in X", "session-based test", no fixed steps | **Exploratory** | `20-mode-exploratory.md` |
| "smoke test", "quick check", "is the app up", "critical paths" | **Smoke** | `21-mode-smoke.md` |
| A Jira key (e.g. `QA-123`), a `.feature` file, "run the X scenario" | **Scenarios** | `22-mode-scenarios.md` |

When you load a mode file, also load any of these you'll need:

- `10-jira-integration.md` — if input or output touches Jira.
- `11-playwright-usage.md` — always, before opening a browser.
- `12-secrets-management.md` — if any step needs credentials, tokens, or API keys.
- `13-test-reporting.md` — always, before producing results.
- `30-bdd-format.md` — auto-loads when a `.feature` file is opened.

## Common preamble (every mode)

Before invoking any mode, do these once:

1. **State the plan.** 3–5 lines: mode, target URL, scope, stop conditions, who owns writeback.
2. **Confirm environment.** Never assume prod. Default to staging/local unless told otherwise.
3. **Confirm writeback.** "Should I post a comment to Jira on completion? (default: no)"
4. **Pre-flight the browser.** Open the target URL, verify HTTP 200, capture a baseline screenshot.

## Common postamble (every mode)

1. Write the local report (`13-test-reporting.md`) to `.kiro/reports/<timestamp>-<mode>.md`.
2. Summarize results in chat: counts of PASS / FAIL / BLOCKED / SKIPPED, plus one-line headline.
3. If Jira writeback was authorized, **draft the comment, show it to the user, wait for "ok"**, then post.
4. Close the browser cleanly.

## Mode comparison cheat-sheet

|  | Exploratory | Smoke | Scenarios |
| --- | --- | --- | --- |
| Has fixed steps? | No | Yes (short) | Yes (BDD) |
| Source of truth | Charter | Smoke list | Jira / `.feature` |
| Typical duration | 30–90 min | 5–15 min | varies |
| Failure stops run? | No (log + continue) | Yes (fail fast) | Per-scenario (continue others) |
| Default Jira writeback | Off | Off | Off (opt-in per run) |
| Primary output | Bug list + notes | Pass/fail grid | Per-scenario report |

## Mode change mid-session

If the user changes mode mid-session, finalize the current report first, then start a new session. Do not append exploratory notes into a scenario run's report.
