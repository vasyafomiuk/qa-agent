---
inclusion: manual
---

# Playwright Usage

This file documents how the agent drives the browser via the Playwright MCP. If you swap to a different browser MCP (Selenium, Puppeteer), replace this file — the rest of the steering is tool-agnostic.

## Expected tool contract

Tool names vary by MCP build. The agent should discover them at session start. The contract:

| Capability | Typical tool names |
| --- | --- |
| Open / close browser | `browser_open`, `browser_close`, `browser_new_context` |
| Navigate | `browser_navigate`, `playwright_goto` |
| Locate elements | `browser_snapshot`, `browser_locator`, `playwright_find` |
| Click | `browser_click`, `playwright_click` |
| Type / fill | `browser_type`, `browser_fill`, `playwright_fill` |
| Read text | `browser_get_text`, `playwright_inner_text` |
| Wait | `browser_wait_for`, `playwright_wait_for_selector` |
| Screenshot | `browser_screenshot`, `playwright_screenshot` |
| Evaluate JS | `browser_evaluate`, `playwright_eval` (use sparingly) |
| Console / network | `browser_console`, `browser_network` |

If a capability is missing, stop and tell the user — do not try to substitute (e.g., do not use `evaluate` to do clicks).

## Selector strategy (in priority order)

1. **Test IDs**: `[data-testid="..."]`, `[data-test="..."]`, `[data-qa="..."]`.
2. **ARIA roles + accessible name**: `role=button[name="Save"]`.
3. **Label text**: `getByLabel("Email")` for form fields.
4. **Visible text**: `getByText("Sign in")` — only for unique, stable labels.
5. **CSS / XPath**: only as a last resort, and only if it's anchored to a semantic element.

**Forbidden** unless no alternative:

- Index-based selectors (`nth-child`, `:nth-of-type`).
- Generated class names (`.css-1a2b3c4`).
- Whole-DOM XPath chains.

If you must use a fragile selector, **note it in the report** so the team can add a `data-testid`.

## Wait strategy

- Prefer **explicit waits for state**: `waitFor({ state: 'visible' })`, `waitFor(response → response.url() === ...)`.
- Use Playwright's auto-waiting on actions — do not insert `sleep`.
- If you need a timeout, default to **10 seconds** for UI, **30 seconds** for full-page navigation. Document any deviation in the report.
- A retry on the SAME selector is allowed once. After that, fail the step.

## Action principles

- **Read before you write.** Before clicking or typing, capture a `browser_snapshot` (or accessibility tree) to confirm the element exists and is in the expected state.
- **One step, one assertion.** Don't bundle "click and verify navigation and verify content" into one tool call.
- **Capture state on failure.** On any step failure, immediately:
  1. Take a full-page screenshot to `.kiro/artifacts/<run>/<step>.png`.
  2. Dump console logs (errors + warnings) to `.kiro/artifacts/<run>/<step>-console.log`.
  3. Dump failing network requests (4xx/5xx) to `.kiro/artifacts/<run>/<step>-network.log`.
- **No production destructive clicks.** Refer to `01-principles.md` — destructive actions need explicit approval.
- **Do not auto-dismiss modals you didn't expect.** A surprise modal is a signal. Capture it and ask the user before clicking through.

## Browser lifecycle

1. Open the browser once per session in a fresh context (no cached cookies).
2. If the scenario needs auth, load it via `storageState` from a known good profile, OR drive the login flow with secrets from `12-secrets-management.md`.
3. Close the browser cleanly at the end of the session (even on failure).
4. If the browser crashes or hangs, kill it, note it in the report, and stop the session — do not silently re-spawn.

## Working with multiple tabs / windows

- Default to single-tab tests. Multi-tab flows must be in the scenario explicitly.
- Always switch to the new tab via the tool API; never use timing assumptions.
- Close auxiliary tabs at scenario boundary.

## When you cannot proceed

- **Element not found after 10s**: capture screenshot + console + DOM snapshot, fail the step with `BLOCKED-UI`.
- **Permission denied (e.g., camera, location)**: pause and ask the user how to handle. Default is **deny**.
- **CAPTCHA / 2FA challenge**: stop. The human handles MFA. Do not attempt to bypass. See `12-secrets-management.md` on TOTP if pre-authorized.

## Performance note

Avoid `browser_evaluate` for things that have a first-class tool. JavaScript evaluation hides intent from the report and the user. Reserve it for genuinely DOM-introspective debugging.
