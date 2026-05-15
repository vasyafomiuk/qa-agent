---
inclusion: manual
---

# Reporting & Practices

## Output locations

- Reports: `~/.kiro/reports/YYYY-MM-DD_HHMMSS_<mode>_<slug>.md`
- Artifacts: `~/.kiro/artifacts/YYYY-MM-DD_HHMMSS_<slug>/`
  - `step-N-<desc>.png` (screenshot)
  - `step-N-console.log`
  - `step-N-network.log`
  - `step-N-dom.html` (on failure)

Reports **link** to artifacts via relative paths. No inline images unless asked.

## Status taxonomy (use exactly these five)

- **PASS** — all assertions met, evidence captured.
- **FAIL** — assertion didn't hold. Include expected / actual / evidence.
- **BLOCKED** — couldn't execute (env, missing data, dependency) — not a product defect.
- **SKIPPED** — intentionally not run. Include reason and approver name.
- **NEEDS-HUMAN** — ambiguous outcome (e.g., UI matched but console errored).

No "WARNING" or "FLAKY-PASS". A retry-then-pass is still PASS with `retry: 1` annotation.

### Evidence requirements

| Status | Required evidence |
| --- | --- |
| PASS | ≥1 screenshot at the assertion point |
| FAIL | Expected/actual, screenshot, console, network |
| BLOCKED | Reason + which prerequisite failed + partial screenshots |
| SKIPPED | Reason + approver |
| NEEDS-HUMAN | Description of ambiguity + all observations |

If you can't capture the required evidence, downgrade to BLOCKED.

## Report skeleton

```markdown
# QA Session — <Mode> — <ISO timestamp>

**Target:**     staging — https://staging.example.com
**Source:**     Jira QA-123 | scenarios/login.feature | charter
**Duration:**   12m 34s
**Browser:**    Chromium 130
**Operator:**   vfomiuk@gmail.com

## Summary
| Status | Count |
| --- | --- |
| ✅ PASS | 7 |
| ❌ FAIL | 1 |
| ⛔ BLOCKED | 0 |
| ⏭ SKIPPED | 1 |
| ❓ NEEDS-HUMAN | 0 |

**Headline:** <one line>

## Scenarios

### 1. <name> — ✅ PASS — 0m 42s
- Given … → ✅ artifact: …
- When …  → ✅
- Then …  → ✅ artifact: …

### 2. <name> — ❌ FAIL — 1m 15s
- Then they receive a reset link → ❌
  - **Expected:** mailbox contains a reset link within 30s.
  - **Actual:**   mailbox empty after 60s; HTTP 500 on `/api/auth/reset`.
  - **Evidence:** artifacts/.../step-3.png, step-3-network.log

## Human decisions
- 11:14 — approved prod read-only smoke.

## Open questions
- Is the 500 a known incident?
```

For exploratory mode, replace the summary's PASS/FAIL grid with severity-hypothesis counts and append an **Observations log** + **Synthesis** section.

## Jira comment format

When writeback is authorized (`10-integrations.md`), generate a comment from:

- The session header.
- The summary table.
- The Scenarios section, truncated to this issue's scenario.
- A link to the local report path.

Do **not** include the "Human decisions" or "Open questions" sections.

## Practices

### Test independence

- Every scenario runnable from a cold start. Dependencies encoded in setup, not run-order.
- Fresh browser context per scenario.
- Named fixtures, not implicit shared state.

### Setup / teardown

- Setup minimal and explicit.
- Teardown is the agent's responsibility for anything created during the test. If it can't clean up, the scenario must say so and the human must approve.

### Evidence cadence

Capture at: before first action (baseline) · after each `Then` · on any failure · before any destructive action · at session end. Avoid screenshots after every `When` — that's noise.

### Flake handling

- Single transient failure → one whole-scenario retry. Mark `retry: 1`.
- Retry passes → PASS with annotation. **Tell the human.**
- Retry fails → FAIL.
- Never mark flaky as clean PASS — that's a HITL call.

### Determinism

- Don't assert on wall-clock time. Assert on events.
- Real network. No mocking unless the scenario explicitly says to.
- Synthetic data, clearly marked. Never real customer data.

### When tests reveal a real bug

Capture full evidence, file as FAIL, surface to human. Do not edit application code. Do not edit the scenario to pass.

### When tests reveal a stale scenario

Mark NEEDS-HUMAN. Describe the mismatch. Propose the update in chat — but do not edit the Jira issue or `.feature` file without explicit approval.

## When report contradicts an earlier chat message

The report is the source of truth. Update it and tell the human you corrected it. Don't let chat and report disagree.
