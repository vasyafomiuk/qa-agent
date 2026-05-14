# Example scenario file. Used by the agent when run with:
#   "run scenarios/login.feature"
#
# Tags drive run behavior. See ../.kiro/steering/22-mode-scenarios.md.

@auth @smoke
Feature: Login
  As a returning user
  I want to sign in with email + password
  So that I can access my dashboard

  Background:
    Given the user is on "/login"

  @prod-safe
  Scenario: Successful login lands on the dashboard
    When they fill the "Email" field with "<email>"
    And they fill the "Password" field with "<password>"
    And they click "Sign in"
    Then the URL should be "/dashboard"
    And they should see "Welcome back"

  Scenario: Wrong password shows an inline error
    When they fill the "Email" field with "qa.user+staging@example.com"
    And they fill the "Password" field with "definitely-wrong"
    And they click "Sign in"
    Then they should see "Incorrect email or password"
    And the URL should be "/login"

  Scenario Outline: Invalid email shape is rejected client-side
    When they fill the "Email" field with "<bad_email>"
    And they fill the "Password" field with "anything"
    And they click "Sign in"
    Then they should see "<error>"

    Examples:
      | bad_email      | error                          |
      | not-an-email   | Enter a valid email address    |
      |                | Email is required              |
      | @nodomain.com  | Enter a valid email address    |

  @destructive @manual
  Scenario: Account lock after 5 wrong passwords
    # Skipped by the agent automatically (manual + destructive).
    # Run with explicit human approval only.
