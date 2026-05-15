---
inclusion: manual
---

# Testing Modes

Three modes. Pick exactly one per session.

|  | Exploratory | Smoke | Scenarios |
| --- | --- | --- | --- |
| Source | Charter | `smoke.yml` | Jira / `.feature` |
| Has fixed steps? | No | Yes (short) | Yes (BDD) |
| Failure stops run? | No | **Yes** (first failure) | Per-scenario (continue others) |
| Typical duration | 30–90 min | 5–15 min | varies |
| Primary output | Observations + themes | Pass/fail grid | Per-scenario report |

## Exploratory

Charter-driven, time-boxed, evidence-rich. Output is **observations**, not verdicts. The human classifies severity.

### Charter (required)

```
CHARTER:  <one-line mission>
AREA:     <feature or page>
TIMEBOX:  <e.g., 30 minutes>
ENV:      <staging | local>
PERSONAS: <e.g., new user, returning admin>
RISKS:    <what we worry about>
OUT-OF-SCOPE: <explicit exclusions>
```

If the user gives a vague request, propose a charter in this shape and wait for yes/edit/no.

### Tours (pick at least three per charter)

Money · Landmark · Antisocial · FedEx (state transitions) · Garbage collector (settings/profile) · Saboteur (mid-action disruption) · Authorization (each role) · Locale · Accessibility (keyboard-only) · Back-button.

Announce each tour before starting. After each, summarize: what visited, what surprised, what to dig into.

### Observation format

```
[HH:MM] <tour> · <page/url>
What I did:       …
What I saw:       …
What surprised:   …
Severity (hyp.):  trivial | minor | major | blocker
Evidence:         <artifact path>
```

### Pause and ask if

- You find something that looks major (data loss, auth break, security).
- You drift off-charter (allowed once with approval).
- You're past 50% of timebox without progress.
- The app is in a state you can't safely reset.

### Don'ts

No PASS/FAIL verdicts. No live Jira posting (aggregate at debrief). No mid-session charter changes. No going past timebox without approval.

## Smoke

Quick critical-path check. Stops on first failure.

### Inputs

- Smoke set at `smoke.yml` (or propose a default and ask).
- Target env URL + auth profile.

### Rules

- Order matters; run in listed order.
- **Stop on first failure.** Continue only if the human asks.
- **No retries.** A flaky smoke is a smoke failure.
- Total runtime under 15 minutes. Longer = smoke set is too big.

### Per-check

```
[N/M] <name> — <one-line description>
  → action
  → assertion
  → ✅ PASS / ❌ FAIL / ⛔ BLOCKED
  → evidence
```

Console errors during a check → **NEEDS-HUMAN** (not auto-fail).

## Scenarios

Run named BDD scenarios end-to-end. Source is either **Jira keys** or **local `.feature`** — never mixed in one run.

### Inputs

1. Source: Jira keys *or* `.feature` path.
2. Target env.
3. Writeback authorization (default: no).
4. Tag filter (`@smoke`, `@regression`, `not @manual`).

List the scenarios and **confirm before running a batch**.

### Execution per scenario

1. Fresh browser context.
2. Run `Background` steps if present.
3. For each step: announce → map to action (`50-bdd.md`) → execute → verify → capture on `Then`.
4. Failure stops *that* scenario; others continue.
5. One whole-scenario retry on transient failures (mark `retry: 1`).
6. Close context.

### Tags (honor these)

- `@smoke` — include in smoke runs.
- `@regression` — full regression suite.
- `@manual` — agent never runs.
- `@wip` — skip unless explicitly requested.
- `@flaky` — never auto-retry; surface every observation.
- `@destructive` — pause for explicit approval, even on staging.
- `@prod-safe` — required for any production run.

### Scenario Outlines

Each `Examples` row is a separate scenario in the report. Use row values in the headline.

### Failure modes

- Missing feature → BLOCKED (possible product change).
- Ambiguous step → stop, ask. Don't guess.
- Background failed → all dependent scenarios in the file are BLOCKED (report once at file level).
- `.feature` parse error → BLOCKED. Do not edit the file.
