---
inclusion: manual
---

# Secrets

Only authoritative source for secret handling. Other files defer to this one.

## Storage backends (resolution order)

The agent walks these top-to-bottom for each secret name. First hit wins.

1. **Process env vars** — `process.env.<NAME>`.
2. **`~/.kiro/config/.env`** — gitignored by virtue of being outside any repo; default.
3. **OS keychain** via 1Password CLI (`op://`) if `OP_VAULT` is set.
4. **AWS Secrets Manager** if `AWS_SECRETS_PREFIX` is set.
5. **HashiCorp Vault** if `VAULT_ADDR` is set.
6. **Prompt the human** — last resort, one-shot, never stored.

## Naming convention

- `QA_<env>_<role>_<field>` — e.g., `QA_STAGING_ADMIN_PASSWORD`.
- `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`.
- `STRIPE_SANDBOX_KEY` — never `*_LIVE_*` in this repo.
- `TOTP_SECRET_<role>` — base32 seed.

If you need a secret whose name doesn't match this convention, stop and ask the human to add it. Don't invent names.

## Redaction (HARD requirements)

The agent must redact secrets in **every** output channel: chat, report, Jira comment, screenshot caption, log, error message.

1. Never print a value verbatim. Substitute `__redacted__`.
2. Never screenshot a form field with a secret value visible. Capture before fill, or mask the field, or screenshot later when the field is gone.
3. Never include URL tokens: redact the query portion `?token=__redacted__`.
4. Never log headers verbatim. Strip `Authorization`, `Cookie`, `X-Api-Key`, and any `*token*`/`*secret*`/`*key*` (case-insensitive).
5. Never dump `.env` contents — point at the file path instead.

## Loading flow

1. Identify the secret by **name**, not value.
2. Resolve via the backend chain.
3. Use in the action; if it's a form-fill, manage screenshots per the redaction rules.
4. After the scenario, drop the value from working memory.

If resolution fails: state which name failed, redact any error detail that includes the value. If not found anywhere, ask the human: *"I need `<NAME>`. Provide it now (one-shot) or abort?"*

## MFA / TOTP

- **Pre-shared seed** (`TOTP_SECRET_<role>`): generate the 6-digit code at the moment of need. The seed never leaves the resolver.
- **Human-supplied code**: pause and ask; treat as one-shot, redact immediately.

Never ask the human to paste the *seed* itself unless setting up backend storage.

## Production secrets

Never load unless **all** of these hold:

1. Human explicitly approved a production session this turn.
2. Secret name includes `PROD` so it's unambiguous in the report.
3. Action is non-destructive (read-only / monitoring smoke).

Default: refuse, recommend staging.

## On leak

If a secret appears in chat, screenshot, or log: tell the human immediately, recommend rotation. Do not try to "clean up" silently.
