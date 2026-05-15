---
inclusion: manual
---

# Integrations — Jira & Playwright MCPs

Both MCPs are assumed already configured in Kiro. On the *first* call of a session, identify the actual tool names the configured server exposes and use them throughout. If a needed capability is genuinely absent, stop and tell the user — never improvise.

## Jira

### Capabilities the agent needs

| Capability | Typical tool name | Required for |
| --- | --- | --- |
| Get issue | `get_issue` | Reading scenarios |
| JQL search | `search_issues` | Bulk fetching test sets |
| Add comment | `add_comment` | Writeback (opt-in per session) |
| Get attachments | `get_attachments` | `.feature` files attached to tickets |
| Transition status | `transition_issue` | **Never invoke** — human-only |

### Reading scenarios

For a key like `QA-123`, look for BDD content in this order:

1. Attachment named `*.feature` → download, parse per `50-bdd.md`.
2. Description block starting with `Feature:` or containing `Scenario:` / `Given/When/Then`.
3. Custom field named "Acceptance Criteria" / "BDD" / "Test Scenario".

Report which source was used. If none, BLOCKED.

For a JQL search, list issues found and **confirm with the user** before running.

### Writing back

**Default: no writeback.** Per-session opt-in only. The agent only adds comments — never transitions, reassigns, edits, or closes.

Handshake:
1. Draft → 2. Show in chat → 3. Ask "Post to <KEY>? (yes/no/edit)" → 4. Post on explicit yes → 5. Quote comment ID/URL back.

Never batch-post. The user approves each one (or explicitly says "post all").

## Playwright

### Capabilities the agent needs

| Capability | Typical tool names |
| --- | --- |
| Browser lifecycle | `browser_open`, `browser_close`, `browser_new_context` |
| Navigate | `browser_navigate` |
| Locate / snapshot | `browser_snapshot`, `browser_locator` |
| Click, fill, type | `browser_click`, `browser_fill`, `browser_type` |
| Wait | `browser_wait_for` |
| Screenshot | `browser_screenshot` |
| Console / network | `browser_console`, `browser_network` |
| Evaluate JS | `browser_evaluate` (sparingly) |

### Selector strategy (priority order)

1. `[data-testid="…"]`, `[data-test="…"]`, `[data-qa="…"]`
2. `role=…[name="…"]`
3. `getByLabel("…")` for form fields
4. `getByText("…")` — unique, stable text only
5. CSS/XPath — last resort

**Forbidden** unless no alternative: index-based selectors (`nth-child`), generated class names (`.css-1a2b3c4`), whole-DOM XPath. If forced, note in the report so the team can add a `data-testid`.

### Wait strategy

- Wait for **state**, not time: `waitFor({ state: 'visible' })`, `waitFor(response => …)`.
- Default UI timeout: 10s. Default nav timeout: 30s. Document deviations.
- One retry on the same selector. After that, fail the step.
- No `sleep`.

### Action principles

- Read before write. Snapshot before clicking; confirm element state.
- One step, one assertion. Don't bundle.
- On failure, capture: full-page screenshot, console (errors+warnings), failing network (4xx/5xx), DOM snapshot.
- Do not auto-dismiss unexpected modals — capture them and ask.

### Browser lifecycle

- Fresh context per session (no cached cookies).
- For auth: load `storageState` from a known profile, or drive UI login with secrets (`30-secrets.md`).
- Close cleanly at end (even on failure). On crash: kill, note, stop — do not silently respawn.

### Multiple tabs

Default single-tab. Multi-tab must be explicit in the scenario. Switch via tool API, never timing. Close auxiliaries at scenario boundary.

### When you cannot proceed

- **Element not found after 10s**: capture state, fail with `BLOCKED-UI`.
- **Permission prompt** (camera, location): default deny, ask the human.
- **CAPTCHA / 2FA**: stop. Human handles MFA (or pre-authorized TOTP, see `30-secrets.md`).
