---
inclusion: manual
---

# Mode: Exploratory Testing

Exploratory testing is **charter-driven, time-boxed, evidence-rich**. The agent is a junior tester pairing with the human. The human supplies the charter and the judgment; the agent supplies systematic coverage, evidence capture, and a clean log.

## Charter format (required input)

Before starting, the agent confirms a charter in this shape:

```
CHARTER: <one-line mission>
AREA:    <feature or page under test>
TIMEBOX: <e.g., 30 minutes>
ENV:     <staging | local | …>
PERSONAS: <e.g., new user, returning admin>
RISKS:   <what we worry about — perf, security UX, data loss, …>
OUT-OF-SCOPE: <explicit exclusions>
```

If the user gives a vague request ("explore the checkout"), the agent **proposes** a charter in this shape and waits for "yes / edit / no". Do not start without one.

## Session structure

1. **Setup (≤ 3 minutes)**: open the app, log in if needed, capture baseline screenshots of the area under test. Confirm the area matches the charter.
2. **Tours (the bulk of the session)**: pick a tour, run it, log observations, repeat.
3. **Debrief (last 5 minutes)**: synthesize, write the report, propose follow-ups.

The agent **announces each tour** before starting it: "Starting *Money tour* — looking at all places that handle currency."

## Tour catalogue (heuristics)

Run the tours that match the charter's risks. Mix at least three per session.

- **Money tour** — wherever the product touches currency, totals, taxes, refunds.
- **Landmark tour** — visit every main nav entry, every primary CTA.
- **Antisocial tour** — submit empty forms, very long strings, special characters, paste binary into text fields.
- **FedEx tour** — track a user-facing object through every state transition.
- **Garbage collector tour** — visit every "settings", "profile", "preferences" page.
- **Saboteur tour** — disconnect network mid-action, navigate away mid-form, double-click submit.
- **Authorization tour** — log in as each role, try to do each other's actions.
- **Locale tour** — switch locales, check date / number / currency formats.
- **Accessibility quick tour** — keyboard-only navigation through the primary task.
- **Back-button tour** — navigate, then back, then forward; does state survive?

When you finish a tour, summarize: "Money tour — visited cart, checkout, refund, invoice. Two issues: tax rounding inconsistency in cart vs. checkout; refund button enabled before payment confirmed."

## Logging observations

Capture continuously. Use this short structure per observation:

```
[HH:MM] <tour> · <page or URL>
What I did: …
What I saw: …
What surprised me: …
Severity hypothesis: trivial | minor | major | blocker (the human classifies)
Evidence: <artifact filename>
```

Severity is a **hypothesis**, never a final call — the human classifies.

## When to pause the human

Pause and ask the human if:

- You find something that **looks** like a major bug (data loss, security exposure, broken auth). Don't keep exploring; let the human triage.
- You drift outside the charter's AREA. Going off-charter is allowed **once per session** with explicit approval.
- You consume more than 50% of the timebox without progress on the charter.
- The application is in a state you can't safely reset (e.g., test account locked, payment partially submitted).

## What you do NOT do in exploratory mode

- **Do not** declare any pass/fail — exploratory mode produces **observations**, not verdicts.
- **Do not** modify the charter mid-session. If the charter is wrong, finalize, debrief, and restart.
- **Do not** post Jira comments on each finding. Aggregate into the report; the human files tickets.
- **Do not** keep going after the timebox unless the human extends it.

## Report layout (exploratory variant)

The exploratory report extends `13-test-reporting.md`'s skeleton with:

- The full **charter** at the top.
- An **observations log** (the continuous capture above).
- A **synthesis** section: themes, top 3 issues, coverage gaps.
- A **next-session proposal**: charter for a follow-up exploratory session.

The summary table shape changes — instead of PASS / FAIL counts, report:

| Severity hypothesis | Count |
| --- | --- |
| Blocker | 0 |
| Major | 2 |
| Minor | 5 |
| Trivial | 3 |
| Question for human | 1 |

## HITL checkpoints (exploratory)

In addition to the global rules in `01-principles.md`, exploratory mode adds:

- **Charter approval** before start.
- **Severity classification** after the session.
- **Decision on whether each observation becomes a Jira ticket** (human files).
- **Whether to schedule a follow-up session.**
