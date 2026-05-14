---
inclusion: manual
---

# Mode: Smoke Testing

Smoke testing answers one question fast: **"Is the application healthy enough to test further?"** Smoke is short, deterministic, and stops the suite on first failure.

## Inputs

The agent needs:

- A **smoke set**: a named list of critical paths. Default location: `.kiro/config/smoke.yml`.
- A **target environment**: URL + auth profile.

If `.kiro/config/smoke.yml` doesn't exist, propose a minimal set based on the app and ask the user to approve. Suggested defaults:

```yaml
# .kiro/config/smoke.yml
smoke:
  - name: app-loads
    description: Home page returns 200 and renders the hero.
  - name: login
    description: Known-good user can log in and see the dashboard.
  - name: navigation
    description: Each primary nav entry is reachable and loads without console errors.
  - name: api-health
    description: /healthz returns 200.
  - name: logout
    description: User can log out and is redirected to the public landing.
```

## Execution rules

- Run checks in the order listed.
- **Stop on first failure.** The point of smoke is fast feedback — keep going only if the human asks.
- No retries on smoke. A flaky smoke is a smoke failure. Tell the human; do not paper over.
- Total runtime should be under **15 minutes**. If it's longer, the smoke set is too big.

## Per-check structure

```
[N/M] <name> — <one-line description>
  → action
  → assertion
  → result: ✅ PASS / ❌ FAIL / ⛔ BLOCKED
  → evidence: <artifact>
```

Console errors during a smoke check count as **NEEDS-HUMAN** (not auto-fail) — sometimes a noisy console is acceptable, but the human should see it.

## Output

A short report (see `13-test-reporting.md`) with:

- Environment + start time + duration.
- A grid: check name → status → first-failure timestamp.
- The exact failure detail if any.
- A one-line headline: "Smoke ✅ — all 5 checks pass in 4m 12s" or "Smoke ❌ — login fails (step 2 of 5) — see step-2.png."

If smoke passes, the report ends there. If smoke fails, the report **stops** at the failure and the agent does not continue to subsequent checks unless the human authorizes.

## When NOT to run smoke

- Right after a deploy without a 60-second settle. Network may still be propagating.
- Against a known-incident environment. Smoke against a broken environment produces noise — confirm the environment first.
- As a substitute for scenario testing. Smoke does not replace acceptance tests.

## HITL checkpoints (smoke)

- Confirm the target env before starting.
- Confirm the smoke set if it deviates from `.kiro/config/smoke.yml`.
- After a smoke failure, ask whether to: (a) continue past the failure, (b) stop and file, (c) reset and retry the env.

## Smoke vs. health check

Smoke includes a real user flow (login, navigate, log out). A pure HTTP health check is one **part** of smoke, not the whole thing. If the user asks for "just a health check," route to a single-step scenario run, not smoke mode.
