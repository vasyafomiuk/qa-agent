---
inclusion: fileMatch
fileMatchPattern: "*.feature"
---

# BDD / Gherkin Format

This file auto-loads when the agent opens a `.feature` file. It also applies to Gherkin extracted from Jira descriptions or attachments (see `10-jira-integration.md`).

## Accepted dialect

The agent reads Gherkin with these rules:

- **Keywords** (case-sensitive, English): `Feature`, `Background`, `Rule`, `Scenario`, `Scenario Outline`, `Examples`, `Given`, `When`, `Then`, `And`, `But`, `*`.
- **Comments**: lines starting with `#` are ignored.
- **Tags**: lines starting with `@` immediately above a `Feature`, `Rule`, or `Scenario`.
- **Doc strings**: triple-quote `"""` blocks; content passed verbatim to the step.
- **Data tables**: pipe-delimited `|` rows; the agent walks rows top-to-bottom for `Examples`.
- **Localization**: only English keywords. If a `.feature` declares `# language: ...`, stop and ask the human to switch to English or use a different runner.

## File structure

```gherkin
# language: en
@feature-tag
Feature: <short feature name>
  As a <persona>
  I want <capability>
  So that <value>

  Background:
    Given <shared precondition>

  @scenario-tag
  Scenario: <distinct flow>
    Given <state>
    When <action>
    Then <observable outcome>

  Scenario Outline: <parameterized flow>
    Given a user with role "<role>"
    When they visit "<page>"
    Then they should see "<expected>"

    Examples:
      | role  | page       | expected        |
      | admin | /dashboard | Admin dashboard |
      | user  | /dashboard | My dashboard    |
```

## How the agent maps steps to actions

The agent does **not** require step definitions in code. It maps each step at execution time via these heuristics. The mapping is announced before the action so the human can intervene.

### Common patterns

| Step shape | Mapped action |
| --- | --- |
| `Given the user is on "<url>"` | `browser_navigate(<url>)` |
| `Given the user is logged in as "<role>"` | Use `storageState` for `<role>` or run login subflow with secret named `QA_<env>_<ROLE>_PASSWORD` (`12-secrets-management.md`). |
| `When they click "<text>"` | `getByRole('button|link', { name: '<text>' }).click()` |
| `When they fill the "<field>" field with "<value>"` | `getByLabel('<field>').fill('<value>')` |
| `When they select "<option>" from "<dropdown>"` | `getByLabel('<dropdown>').selectOption('<option>')` |
| `Then they should see "<text>"` | `expect(getByText('<text>')).toBeVisible()` |
| `Then the URL should be "<path>"` | `expect(page).toHaveURL(...path...)` |
| `Then the "<field>" field should show "<value>"` | `expect(getByLabel('<field>')).toHaveValue('<value>')` |

If a step doesn't match any pattern, the agent stops and asks the human to translate it. Do **not** guess.

### Authentication steps

`Given the user is logged in as "<role>"` resolves credentials by **name**, not value:

1. Try `storageState` at `.kiro/config/storage-states/<env>-<role>.json` if it exists.
2. Otherwise drive a UI login using `QA_<env>_<ROLE>_EMAIL` and `QA_<env>_<ROLE>_PASSWORD` from `12-secrets-management.md`.
3. If neither exists, BLOCKED — ask the human to set up the profile.

### Steps that mention real services

If a step mentions email, SMS, payment, or any external service, default to the **sandbox** version. If no sandbox is configured, BLOCKED — never send real messages or charges in a test.

## Tag semantics (recap)

See `22-mode-scenarios.md` for the full list. Critical ones:

- `@destructive` — pause for human approval before running.
- `@prod-safe` — required for any production run.
- `@manual` — agent never runs.
- `@wip` — agent skips by default.

## Parse errors

If a `.feature` file is malformed, the agent **does not edit it**. It reports the file as BLOCKED with the exact parse error line/column and asks the human to fix.

## Examples table evaluation

Each row of `Examples` becomes one scenario. The agent substitutes `<param>` placeholders with row values **once** at scenario start; no in-step interpolation.

Empty cells:
- Empty string `""` → fail the row with "missing value for `<param>`".
- Cell with literal `""` (two quotes) → use empty string.
- Cell with `<nil>` or `(null)` → BLOCKED, ambiguous — ask the human.

## Doc strings and data tables

- A doc string after a step is passed as the step's body. Useful for "Given the following JSON: …".
- A data table after a step is iterated row-by-row. Failures are per-row.

## Limits

- A single scenario should run in under **5 minutes**. Longer scenarios indicate they should be split.
- A feature file should hold at most **10 scenarios**. Larger files mean the file is becoming a suite.
- Step lines should be readable English. If a step is over 200 characters, that's a smell — surface it to the human.
