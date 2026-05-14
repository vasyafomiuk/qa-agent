---
inclusion: manual
---

# Testing Best Practices

These are the engineering norms the agent applies regardless of mode. They are deliberately opinionated.

## Test independence

- Each scenario must be runnable from a cold start. If Scenario B depends on the output of Scenario A, that dependency must be encoded in **setup**, not in run-order.
- The agent never assumes browser state survives across scenarios. Each scenario gets a fresh browser context.
- Shared fixtures (test users, test data) must be **named** in the scenario, not implicit.

## Setup / teardown

- Setup should be minimal and explicit. Prefer scenarios that arrange their own state in the UI (or via documented seed APIs).
- Teardown is the agent's responsibility for anything **created during the test**: test users, draft documents, uploaded files. If the test can't clean up, the scenario must say so up front and the human must approve.
- Never reuse production accounts as test fixtures.

## Evidence capture cadence

Capture at these moments:

1. **Before the first action** of each scenario (baseline).
2. **After each `Then` step** (assertion evidence).
3. **On any failure**, even if recoverable.
4. **Before any destructive action** (so the pre-state is recorded).
5. **At session end** (final state of the application).

Don't over-capture. A screenshot after every `When` is noise.

## Determinism vs. flakiness

A test should produce the **same status** on three back-to-back runs in a stable environment. If it doesn't, it's flaky.

Agent rules for handling flake:

- A single transient failure (e.g., network blip) → retry the **scenario** (not the step) once. Mark as `retry: 1` in the report.
- If retry passes → record PASS with `retry: 1` annotation. **Tell the human** the test is suspect.
- If retry fails → FAIL.
- Three flaky observations across the team's recent runs → recommend the human quarantine the scenario.

The agent **never** marks a flaky test as a clean PASS without the annotation. That's a HITL decision.

## Assertion granularity

- One conceptual check per assertion. "Dashboard loads with the user's name and three widgets" is **three** assertions.
- Prefer positive assertions (`expect(toBeVisible)`) over negative (`expect(not toBeVisible)`). Negative assertions race with rendering.
- Avoid asserting on transient UI states (a spinner) unless the spinner *is* the feature.

## Selectors and stability

See `11-playwright-usage.md` for the priority order. When a scenario forces you to use a brittle selector:

1. Note it explicitly in the report: "Used `.css-1a2b3c4 > div:nth-child(2)` — recommend adding `data-testid='cart-item-row'`."
2. File a follow-up note (the human can convert it to a ticket).

## Data hygiene

- Use synthetic data that's clearly marked: `qa.user+staging+2026-05-14@example.com`. Never realistic-looking PII.
- If the scenario requires uploading a file, use the fixtures in `scenarios/fixtures/` (or ask the human to add one). Do not generate random binary blobs.
- Never test with real customer data, even read-only.

## Concurrency

- The agent runs scenarios **sequentially** by default. Parallel execution is a HITL decision (it changes data assumptions).
- If asked to parallelize, refuse for any scenario that writes shared state.

## Time-based assertions

- Don't assert on wall-clock time. Assert on **events** (request observed, element appeared).
- For "within N seconds" assertions, use Playwright's waitFor with an explicit timeout.

## Browser configuration

- Default: a fresh, headed Chromium context (so the human can watch).
- Viewport: 1280×800 unless the scenario is responsive-specific.
- Locale: en-US, timezone: UTC, unless the scenario is localization-specific.
- Network: real network. Do not mock unless the scenario explicitly says to.

## When tests reveal a real bug

- Do not edit application code.
- Do not edit the scenario to make it "pass".
- Capture full evidence, file a finding in the report (`FAIL` with hypothesis), and surface to the human.

## When tests reveal a stale scenario

If the scenario is wrong (selector, expected text, assumption), the agent should:

1. Mark the result `NEEDS-HUMAN`.
2. Describe the mismatch in detail: "Scenario expects 'Welcome back' but UI now says 'Hi, <name>'."
3. Propose the update in chat — but **do not edit the Jira issue or the `.feature` file** without explicit approval.

## Code-free QA

- The agent should not invent helper scripts, utilities, or test frameworks while executing a session.
- If a need for reusable code appears, surface it as a follow-up to the human.
- The agent **executes** tests; engineers **build** test infrastructure.
