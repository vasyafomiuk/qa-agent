---
inclusion: manual
---

# Jira Integration

This file documents how the agent reads test scenarios from Jira and (when authorized) writes results back. The agent depends on a Jira MCP server being configured in Kiro. Tool names may vary by server; the agent should discover them at the start of a session and adapt.

## Expected MCP capability

The agent expects tools that match this contract. Exact names vary — look for them at session start.

| Capability | Typical tool name | Required for |
| --- | --- | --- |
| Fetch issue by key | `get_issue`, `getJiraIssue`, `jira_issue` | Reading scenarios |
| Search by JQL | `search_issues`, `jql_search`, `jira_search` | Bulk fetching test sets |
| Add comment | `add_comment`, `jira_add_comment` | Writeback (opt-in) |
| Get attachments | `get_attachments`, `download_attachment` | `.feature` files attached to tickets |
| Transition status | `transition_issue` | **Human-only** — never invoke autonomously |

At the start of a Jira-touching session, run `list_tools` (or equivalent) and confirm the available subset. If a required capability is missing, **stop and tell the user** — do not improvise.

## Reading scenarios from Jira

### Single issue

When the user gives a key like `QA-123`:

1. Fetch the issue.
2. Look for BDD content in this priority order:
   - An attachment named `*.feature` → download it, parse per `30-bdd-format.md`.
   - A description block that starts with `Feature:` or contains `Scenario:` / `Given/When/Then` lines → extract the Gherkin block verbatim.
   - A custom field commonly named "Acceptance Criteria" / "BDD" / "Test Scenario" → extract.
3. If multiple sources exist, prefer the attachment, then the description, then the custom field. Report which source you used.
4. If none exist, mark the issue **BLOCKED — no scenario** and ask the user how to proceed.

### Multiple issues (test suite)

When the user wants to run a set:

1. Ask for the JQL (or accept a label / fix-version / epic link).
2. Execute the search and list the issues found.
3. **Confirm the list with the user** before running. Do not run a 50-issue suite silently.
4. Run scenarios in order; do not stop the suite on a single failure — record and continue.

### Useful JQL patterns

Document patterns the team can copy:

```
# All open test cases for a release
project = QA AND issuetype = "Test Case" AND fixVersion = "2026.5" AND status != Done

# Smoke set
project = QA AND labels = smoke AND status != Closed

# Regressions assigned to me
project = QA AND assignee = currentUser() AND labels = regression
```

## Writing results back to Jira

**Default: NO writeback.** The user must authorize writeback at the start of each session. Authorization is per-session, not persistent.

### Comment-only policy

The agent **only adds comments**. The agent does **not**:

- Transition issue status.
- Reassign.
- Set fix versions or labels.
- Edit the description or any field.
- Close or reopen the issue.

If the user asks for any of those, do them via `/help` instructions or explicitly delegate back: "I won't change the status — please do that yourself once you've reviewed the comment."

### Comment template

Use this format (also in `13-test-reporting.md`):

```
*QA Agent — <Mode> — <ISO timestamp>*

*Result:* PASS | FAIL | BLOCKED
*Environment:* <env name + base URL>
*Duration:* <m:ss>
*Source:* <Jira description | attachment:filename.feature | local file>

*Steps:*
- ✅ Given the user is on the login page
- ✅ When they enter valid credentials
- ❌ Then they should see the dashboard
  - Failure: expected element `[data-testid=dashboard-greeting]`, not found after 10s.
  - Evidence: .kiro/artifacts/<run>/step-3.png

*Artifacts:*
- Report: .kiro/reports/<run>.md
- Screenshots: .kiro/artifacts/<run>/

*Notes:*
<one or two lines, optional>
```

### Authorization handshake (must follow exactly)

1. Draft the comment.
2. Show the rendered draft in chat.
3. Ask: "Post this comment to <ISSUE-KEY>? (yes / no / edit)".
4. Only post on explicit "yes".
5. After posting, quote the comment ID and link in chat for the user's audit trail.

## Secrets and Jira

A Jira token is itself a secret. See `12-secrets-management.md`. Never include the token in chat output, the local report, or a posted comment. If the MCP server fails to authenticate, surface the error message **with the token redacted**.

## Failure handling

- **Issue not found** → BLOCKED, stop the session, ask the user to verify the key.
- **Permission denied on add_comment** → keep the local report, surface the permission error, ask the user to comment manually (offer the rendered draft).
- **Rate limit** → wait the suggested time, retry **once**, then surface to the user.
