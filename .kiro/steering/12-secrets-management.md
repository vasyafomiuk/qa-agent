---
inclusion: manual
---

# Secrets Management

This file documents how the agent obtains, uses, and protects secrets (passwords, API tokens, OAuth tokens, TOTP seeds, payment sandbox keys). It is the **only** authoritative source for this topic — other files defer to it.

## Storage backends (in priority order)

The agent supports multiple backends. The default is **environment variables sourced from a gitignored `.env` file**. Teams should pick a backend, document it in their project's `99-project-overrides.md`, and stick with it.

| Backend | Trigger | Notes |
| --- | --- | --- |
| Process env vars | Always checked first | `process.env.QA_USER_PASSWORD` style |
| `.env` file at `.kiro/config/.env` | Auto-loaded if present | **Must be gitignored** |
| OS keychain (1Password CLI, `op://`) | If `OP_VAULT` env var is set | Requires `op` CLI logged in |
| AWS Secrets Manager | If `AWS_SECRETS_PREFIX` is set | Requires AWS creds in env |
| HashiCorp Vault | If `VAULT_ADDR` is set | Requires `VAULT_TOKEN` |
| Prompt the human | Last resort | One-shot, never stored |

The agent walks the list top-to-bottom for each secret name. The first hit wins.

## Naming convention

Use uppercase snake-case, prefixed by purpose:

- `QA_<env>_<role>_<field>` — e.g. `QA_STAGING_ADMIN_PASSWORD`, `QA_PROD_READONLY_PASSWORD`.
- `JIRA_API_TOKEN`, `JIRA_BASE_URL`, `JIRA_EMAIL`.
- `STRIPE_SANDBOX_KEY` — never `STRIPE_LIVE_KEY` in this repo.
- `TOTP_SECRET_<role>` — base32 seed only, generated alongside the test account.

If a secret you need doesn't match this convention, stop and ask the human to add it. Do not invent new names on the fly.

## Sample `.env` (do not commit)

A template is provided at `.kiro/config/secrets.example.env`. Copy to `.kiro/config/.env` and fill in:

```env
# Jira (used by the Jira MCP, mirrored here for reference)
JIRA_BASE_URL=https://your-org.atlassian.net
JIRA_EMAIL=qa-bot@your-org.com
JIRA_API_TOKEN=__redacted__

# Test users — staging
QA_STAGING_BASE_URL=https://staging.example.com
QA_STAGING_USER_EMAIL=qa.user+staging@example.com
QA_STAGING_USER_PASSWORD=__redacted__
QA_STAGING_ADMIN_EMAIL=qa.admin+staging@example.com
QA_STAGING_ADMIN_PASSWORD=__redacted__

# Optional: TOTP seed for accounts that require MFA
TOTP_SECRET_STAGING_USER=__redacted_base32__

# Sandbox payment
STRIPE_SANDBOX_KEY=sk_test___redacted__
```

## Redaction rules (HARD requirements)

The agent must redact secrets in **every** output channel: chat, local report, Jira comment, screenshot caption, log file, error message.

1. **Never** print a secret value verbatim. Substitute `__redacted__`.
2. **Never** screenshot a form field with a secret value still typed in plaintext. Either:
   - Take the screenshot **before** filling the field.
   - Mask the field via DOM tooling before screenshotting.
   - Take a screenshot at a later step where the field is no longer visible.
3. **Never** dump full URLs that contain tokens in query strings. Redact the token portion: `?token=__redacted__`.
4. **Never** log request headers verbatim. Strip `Authorization`, `Cookie`, `X-Api-Key`, and any header matching `*token*` / `*secret*` / `*key*` case-insensitive.
5. **Never** include the raw `.env` contents in any output, even on user request — refer them to the file path.

## Loading secrets (workflow)

When a scenario needs a secret, the agent must:

1. Identify the secret by **name**, not value (e.g., "I need `QA_STAGING_USER_PASSWORD`").
2. Resolve via the backend chain. Do **not** log the value.
3. Use it in the action. If the action is a form-fill, take any required screenshot **before** the fill, or with the field masked.
4. After the scenario, drop the value from working memory. Do not summarize it back.

If resolution fails:
- Backend lookup error → tell the user which name failed, redact any error detail that includes the value.
- Not found anywhere → ask the human: "I need `<NAME>` to complete this step. Provide it now (it will be used only for this session), or abort?"

## MFA / TOTP

Two acceptable flows:

1. **Pre-shared TOTP seed.** Stored as `TOTP_SECRET_<role>`. The agent generates a one-time code at the moment of need. The seed itself never leaves the resolver — only the 6-digit code is typed.
2. **Human-supplied code.** The agent pauses and asks: "MFA required. Paste the current 6-digit code." The code is treated as one-shot and redacted immediately.

**Never** ask the human to paste the TOTP seed itself unless they're setting up backend storage.

## Production secrets

Production secrets must **never** be loaded by the agent unless:

1. The user has explicitly approved a production session this turn.
2. The secret name includes `PROD` so it's unambiguous in the report.
3. The action being taken is non-destructive (read-only check, or a documented monitoring smoke test).

Default: refuse and recommend running against staging instead.

## Rotation / revocation

When a session ends, you do not need to do anything with secrets — they live in their backend. But if a test session **leaked** a secret (it appeared in chat, a screenshot, a log), tell the user immediately and recommend rotation. Do not try to "clean up" the leak silently.
