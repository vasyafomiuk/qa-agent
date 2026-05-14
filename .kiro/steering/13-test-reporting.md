---
inclusion: manual
---

# Test Reporting

This is the only authoritative report format for the QA agent. Every session produces a local report. Jira comments derive from the same data.

## Where reports go

- **Per-session report**: `.kiro/reports/YYYY-MM-DD_HHMMSS_<mode>_<slug>.md`
  - `mode`: `exploratory`, `smoke`, or `scenarios`.
  - `slug`: e.g., Jira key, `.feature` filename, or charter name.
- **Artifacts directory**: `.kiro/artifacts/YYYY-MM-DD_HHMMSS_<slug>/`
  - Screenshots: `step-N-<short-desc>.png`.
  - Console logs: `step-N-console.log`.
  - Network errors: `step-N-network.log`.
  - DOM snapshot on failure: `step-N-dom.html`.

The report **links** to artifacts via relative paths. Do not embed images inline unless the user asks.

## Report skeleton

```markdown
# QA Session — <Mode> — <ISO timestamp>

**Target environment:** staging — https://staging.example.com
**Source:** Jira QA-123 | scenarios/login.feature | exploratory charter
**Duration:** 12m 34s
**Browser:** Chromium 130 (headed)
**Operator:** vfomiuk@gmail.com (HITL)
**Agent:** Kiro QA Agent

## Summary

| Status | Count |
| --- | --- |
| ✅ PASS | 7 |
| ❌ FAIL | 1 |
| ⛔ BLOCKED | 0 |
| ⏭ SKIPPED | 1 |
| ❓ NEEDS-HUMAN | 0 |

**Headline:** Login flow passes; password-reset email link returns 500 (see Scenario 4).

## Scenarios / Steps

### 1. Successful login — ✅ PASS — 0m 42s
- Given the user is on the login page → ✅ artifact: artifacts/.../step-1.png
- When they enter valid credentials → ✅
- Then they see the dashboard → ✅ artifact: artifacts/.../step-3.png

### 2. Password reset — ❌ FAIL — 1m 15s
- Given the user clicks "Forgot password" → ✅
- When they request a reset email → ✅
- Then they receive a reset link → ❌
  - **Expected:** mailbox contains a reset link within 30s.
  - **Actual:** mailbox empty after 60s; backend returned HTTP 500 to `/api/auth/reset`.
  - **Evidence:** artifacts/.../step-3.png, artifacts/.../step-3-network.log
  - **Hypothesis (low confidence):** the email service queue may be backed up; recheck after 5 min.

## Decisions made by the human during this session

- 11:14 — approved production read-only smoke pass.
- 11:22 — chose to skip Scenario 5 (regression QA-456) due to known dependency outage.

## Open questions for the human

- Is the 500 on `/api/auth/reset` a new bug or a known incident?
- Should I retry the skipped scenario after the dependency is restored?

## Artifacts

- Report: this file
- Screenshots & logs: `artifacts/2026-05-14_111200_qa-123/`
```

## Status taxonomy

Use exactly these five statuses. Do not invent new ones.

- **PASS** — All assertions met. Evidence captured.
- **FAIL** — An assertion did not hold. Includes expected/actual/evidence.
- **BLOCKED** — Could not execute due to environment / dependency / missing data (not a product defect). Includes the blocker reason.
- **SKIPPED** — Intentionally not run. Includes the reason and who approved the skip.
- **NEEDS-HUMAN** — Outcome is ambiguous (e.g., UI matched but a console error appeared). Surface to the human for classification.

Do not invent a "WARNING" or "FLAKY-PASS" status. A retry-after-pass is still PASS, with a `retry: 1` annotation in the step.

## Evidence requirements

Every status MUST include the evidence below. If you cannot capture it, downgrade to BLOCKED.

| Status | Required evidence |
| --- | --- |
| PASS | At least one screenshot at the assertion point. |
| FAIL | Expected/actual values, screenshot, console log, network log. |
| BLOCKED | Reason + which prerequisite failed + any partial screenshots. |
| SKIPPED | Reason + name of the human who approved the skip. |
| NEEDS-HUMAN | Description of ambiguity + all observations. |

## Jira comment format

When writeback is authorized (`10-jira-integration.md`), the agent generates a comment by extracting:

- The session header (env, source, duration, browser).
- The summary table.
- The Scenarios/Steps section, truncated to the issue's own scenario.
- A link to the local report path (so the engineer can pull it from the QA machine if needed).

The agent does **not** post:

- The "Decisions made by the human" section (internal to the QA session).
- Open questions (those are for the user, not the issue thread).
- Inline screenshots (link only, unless the user opts to attach).

## When the report contradicts your earlier message

The report is the source of truth. If you stated PASS in chat then realized the assertion was wrong, **update the report** and tell the human you've corrected it. Do not let chat and report disagree.
