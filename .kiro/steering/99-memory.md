---
inclusion: always
---

# Memory

The agent's persistent memory for this user. Loads last so memory wins on conflict with `00`–`50`. The **Store** section below is the canonical record — the user reads and edits it; the agent appends per the **Skill** rules.

## Skill

### Triggers

- **Remember**: "remember that …", "remember: …", "for next time …", "/remember …", "save this preference: …", "make a note that …".
- **Forget**: "forget …", "remove the memory about …", "ignore the rule about …".
- **Recall**: "what do you remember about …?", "/memory", "/recall …".
- **Correction follow-up**: when the user just corrected you, offer once: *"Want me to remember 'X'?"* Don't nag.

If unclear whether persistent vs. session, ask: *"Save to memory or just this session?"*

### Categories (use exactly these)

| Category | Contents |
| --- | --- |
| **Preferences** | Tone, verbosity, default modes, default env, report style. |
| **Corrections** | Rules from past corrections. Encode the underlying rule, not the surface fix. |
| **Routes & locations** | URLs, paths, Jira project keys, dashboards, channels. |
| **Facts** | Env- or project-specific truths that don't fit elsewhere. |
| **People** | Who to ping for what. |

If a candidate doesn't fit any category, ask. Don't invent new ones.

### Entry format

One bullet. Lead with the rule/fact. Optional trailing `— Why: …`, `— Where: …`, `— YYYY-MM-DD`.

### What NOT to record

- **Secrets/tokens/passwords** — route to `30-secrets.md`.
- Ephemeral state ("working on QA-123 today").
- Anything already in code or git history.
- Vague guidance ("be careful with X").
- PII beyond what's needed to operate.

### Write workflow

1. Categorize. State the proposed bullet text.
2. Dedupe — if a near-match exists, propose an *update*, not a duplicate. Show both side-by-side.
3. Confirm: *"Save under <Category>: `<bullet>` — yes / edit / no?"*
4. Append under the right section in this file. Preserve section order.
5. Echo the saved entry.

**Never silently append.** Confirmation is non-negotiable.

### Update / remove

Quote the existing entry verbatim → show proposed change (or "remove this") → confirm → edit → echo.

### Apply (every session)

Hold this file's contents as guidance. On conflict with `00`–`50`, follow memory and surface the conflict the first time you act on it: *"Memory says X; `40-reporting.md` says Y. Following X. Update steering too?"*

### Suspend

"Ignore memory for this run" / "skip memory" → memory paused for one turn. Announce: *"Memory paused."* Don't delete the file.

### Hygiene

Before acting on an entry that names a specific URL, Jira key, person, or path, verify it still exists when feasible. If gone, flag: *"Memory says X but I can't find it. Update or remove?"*

---

## Store

<!--
Format: one bullet per entry, lead with rule/fact. Optional `— Why: …` `— Where: …` `— YYYY-MM-DD`.
The agent appends here under the matching section. Users can also edit by hand.
-->

### Preferences

### Corrections

### Routes & locations

### Facts

### People
