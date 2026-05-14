---
inclusion: always
---

# Memory Skill

The agent has a persistent memory file at `.kiro/steering/99-memory.md` (always-loaded). This skill defines how the user **adds**, **updates**, and **removes** memory entries, and how the agent **applies** them in future sessions.

The memory file is the only place the agent writes persistent state. Everything else is per-session.

## Recognizing a "remember" request

Treat these as triggers, regardless of exact phrasing (case-insensitive):

- **Explicit**: "remember that …", "remember: …", "for next time, …", "/remember …", "save this preference: …", "make a note that …".
- **Correction follow-up**: when the user just corrected you, proactively offer once: *"Want me to remember 'X' so I don't repeat that?"* — accept on "yes"; don't nag.
- **Project intel**: when the user shares a route, dashboard, owner, or environment fact that obviously generalizes ("the admin panel lives at /admin/v2"), offer to remember.

If unclear whether a note is **persistent** or **just for this session**, ask once:
> "Save this to memory (persistent across sessions) or keep it just for this session?"

## Recognizing a "forget" request

Triggers: "forget …", "remove the memory about …", "ignore the rule about …", "I no longer use …", "/forget …".

## Recognizing a "recall" request

Triggers: "what do you remember about …?", "what's in memory?", "/memory", "/recall …".

When asked, **quote the matching entries verbatim** from `99-memory.md`. Do not paraphrase. If nothing matches, say so plainly.

## Categories (use these exactly)

Every memory entry lives in one of these sections in `99-memory.md`. If a candidate entry doesn't fit, ask the user which category — don't invent new ones.

| Category | What goes here |
| --- | --- |
| **Preferences** | How the user wants you to work: tone, verbosity, default modes, default env, report style. |
| **Corrections** | Rules established by past corrections. Encode the *underlying rule*, not the surface fix. Include the *why* if non-obvious. |
| **Routes & locations** | URLs, paths, Jira project keys, dashboards, channels — anything navigation-shaped. |
| **Facts** | Env-specific or project-specific truths that don't fit elsewhere. |
| **People** | Who to ping for what (first name + role + when). |

## Entry format

One bullet per entry. Keep it short and scannable.

```
- <Rule or fact in one sentence.> — Why: <one line, only if non-obvious>. — Where: <scope, only if narrower than "always">. — <YYYY-MM-DD>
```

The trailing date helps future-you decide if the entry has decayed. The `Why:` and `Where:` parts are optional but encouraged for corrections.

**Examples** (don't add these to memory — they're illustrative):

- `- Default test environment is staging; prod requires explicit per-session approval. — 2026-05-14`
- `- Use 'role=button' selectors over CSS classes. — Why: design system regenerates class names per build. — 2026-05-14`
- `- Bug tracker for QA findings: Jira project QA-BUGS (not ENG). — 2026-05-14`

## What NOT to record

Refuse politely and explain:

- **Secrets / tokens / passwords.** Memory is plaintext and committable. Route to `12-secrets-management.md`.
- **Ephemeral state.** "I'm working on QA-123 today" — that's session context, not memory.
- **Content already in code or git history.** "We use Playwright" — codebase shows that.
- **Vague guidance.** "Be careful with the checkout flow." If you can't quote a concrete rule, ask the user to sharpen it.
- **Anything Personal Identifiable** beyond what's needed to operate (no employee phone numbers, no customer data).

## Write workflow

When the user authorizes a save:

1. **Categorize.** State the category aloud and the proposed bullet text.
2. **Dedupe.** Search `99-memory.md` for a near-match. If one exists, propose an *update* instead of a duplicate. Show the existing entry and the new one side-by-side.
3. **Confirm.** "Save under *Preferences*: `<bullet>` — yes / edit / no?"
4. **Append.** Edit `99-memory.md`, appending under the right section. Preserve the section order and the HTML comments that document the format.
5. **Echo.** Quote the saved entry back to the user.

Never write to memory silently. The confirmation step is non-negotiable.

## Update / remove workflow

1. Quote the existing entry verbatim.
2. Show the proposed change (or "remove this entry").
3. Confirm with the user.
4. Edit `99-memory.md`.
5. Echo the result.

## Apply workflow (every session)

At session start, after loading the always-included steering files:

1. Scan `99-memory.md`. If empty, do nothing — memory has not been seeded yet.
2. Hold its contents alongside the other steering as guidance for this session.
3. **Memory wins on conflict.** If a memory entry contradicts an older steering file (01–30), follow the memory but surface the conflict the *first* time you act on it: *"Memory says X; `13-test-reporting.md` says Y. Following X. Want me to update the steering file too?"*

## Suspending memory

If the user says "ignore memory for this run", "skip memory", or similar, treat memory as **paused for this turn only** — announce it: *"Memory paused for this run."* Do not delete or comment out the file.

## Hygiene

Before applying a memory entry that names a specific URL, Jira key, person, or file path, verify it still exists when feasible. If the referenced thing is gone, flag it: *"Memory says `/admin/v2` but that returns 404. Update or remove?"*

If `99-memory.md` grows past ~50 entries, propose a cleanup pass — many of those are likely stale.

## Privacy & sharing

The memory file is committed to the repo by default — it's project context the team shares. Two ways to keep entries personal:

- Add an "(personal)" suffix to a bullet and ask teammates not to overwrite.
- Add `.kiro/steering/99-memory.md` to `.gitignore` if you want fully personal memory.

Tell the user which model they're using if they ask — don't assume.
