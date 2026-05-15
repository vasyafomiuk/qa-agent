---
inclusion: fileMatch
fileMatchPattern: "*.feature"
---

# BDD / Gherkin

Auto-loads on `*.feature`. Also applies to Gherkin extracted from Jira.

## Accepted dialect

English keywords only. `Feature`, `Background`, `Rule`, `Scenario`, `Scenario Outline`, `Examples`, `Given`, `When`, `Then`, `And`, `But`, `*`. Comments start with `#`. Tags start with `@` immediately above a `Feature` / `Rule` / `Scenario`. Doc strings use `"""`. Data tables use `|`.

If the file declares non-English `# language: …`, stop and ask the human.

## Structure

```gherkin
@feature-tag
Feature: <name>

  Background:
    Given <shared precondition>

  @scenario-tag
  Scenario: <distinct flow>
    Given <state>
    When  <action>
    Then  <observable outcome>

  Scenario Outline: <parameterized>
    Given a user with role "<role>"
    When  they visit "<page>"
    Then  they should see "<expected>"

    Examples:
      | role  | page       | expected        |
      | admin | /dashboard | Admin dashboard |
      | user  | /dashboard | My dashboard    |
```

## Step → action mapping

The agent maps steps at runtime. **No step definitions in code.** Announce the planned action before executing.

| Step shape | Mapped action |
| --- | --- |
| `Given the user is on "<url>"` | `browser_navigate(<url>)` |
| `Given the user is logged in as "<role>"` | `storageState` for `<role>`, else UI login using `QA_<env>_<ROLE>_PASSWORD` |
| `When they click "<text>"` | `getByRole('button\|link', { name: '<text>' }).click()` |
| `When they fill the "<field>" field with "<value>"` | `getByLabel('<field>').fill('<value>')` |
| `When they select "<option>" from "<dropdown>"` | `getByLabel('<dropdown>').selectOption('<option>')` |
| `Then they should see "<text>"` | `expect(getByText('<text>')).toBeVisible()` |
| `Then the URL should be "<path>"` | `expect(page).toHaveURL(<path>)` |
| `Then the "<field>" field should show "<value>"` | `expect(getByLabel('<field>')).toHaveValue('<value>')` |

If a step doesn't match any pattern, stop and ask the human to translate. **Don't guess.**

### Auth steps

`Given the user is logged in as "<role>"`:
1. `storageState` at `~/.kiro/config/storage-states/<env>-<role>.json` if present.
2. Else UI login using `QA_<env>_<ROLE>_EMAIL` + `QA_<env>_<ROLE>_PASSWORD` (`30-secrets.md`).
3. Else BLOCKED — ask the human to set up the profile.

### Real-service steps

Steps mentioning email, SMS, payment, or external services default to the **sandbox** version. No sandbox configured = BLOCKED. Never send real messages or charges.

## Tags

- `@destructive` — pause for approval, even on staging.
- `@prod-safe` — required for any production run.
- `@manual` — never run.
- `@wip` — skip by default.
- `@smoke` / `@regression` — informational filters.

Unknown tags: record but no behavior change.

## Examples table

Each row → one scenario. `<param>` placeholders substituted once at scenario start.

- `""` (literal two quotes) → empty string.
- empty cell → fail with "missing value for `<param>`".
- `<nil>` / `(null)` → BLOCKED, ambiguous.

## Parse errors

The agent **does not edit** the `.feature` file. Report BLOCKED with the exact line/column and ask the human to fix.

## Limits

- Scenario duration under 5 min — longer means split.
- File holds at most ~10 scenarios.
- Step lines under 200 chars.
