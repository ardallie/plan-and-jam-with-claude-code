# Plan workflow

Multi-session workflow for planning, validating, and implementing features. Each session uses a separate Claude Code instance — sessions do not share context. The GitHub issue is the bridge between sessions.

## Source of truth

- **Planning session:** Local plan file (`~/.claude/plans/`)
- **After publishing:** GitHub issue

Once the plan is published to GitHub, the issue becomes the single source of truth.
Avoid entering plan mode in subsequent sessions — this creates duplicate local files that diverge from the issue.

**Issue structure:**
- Description: Plan (living document, updated via `/plan-update`)
- Comments: Handoffs documenting implementation progress

## Plan

Design the implementation and publish it.

1. Enter plan mode to explore the codebase and design the approach
2. Claude writes the plan to `~/.claude/plans/`
3. `/plan-create` — publishes the plan to a new GitHub issue
4. Keep the session open — you will return to it after validation

## Validate

A fresh session provides perspective the planning session lacks. Assumptions become visible, gaps surface, and ambiguities clarify.

1. `/plan-validate <issue>` — loads the plan (chains `/plan-read` internally), validates against the codebase, and interviews you if findings need clarification
2. The command outputs a structured report with an instruction header, findings, and any clarifications
3. The report is copied to the clipboard automatically

## Revise

Return to the planning session and paste the validation report. The report's instruction header tells the planning agent to:

1. Enter plan mode and address the findings
2. Exit plan mode
3. Run `/plan-update` to push revisions to the GitHub issue

The planning agent does not proceed with implementation — it only updates the plan.

## Implement

Execute the plan and document the work.

1. `/plan-read <issue>` — loads the plan and any handoff comments from prior sessions
2. Implement the plan
3. `/plan-handoff` — documents what was done as an issue comment, capturing decisions, gotchas, and verification steps not obvious from the diff
4. `/agent-code-review` — runs a pre-PR agent review with four specialised reviewers
5. Address critical and high-severity findings before proceeding
6. `/pr-create` — creates a pull request from the current branch

## Team review

Pre-PR code review intended for non-trivial changes. The report is copied to the clipboard for reference. See step 4 of the Implement section above.

## Review

Respond to PR feedback after code review.

1. `/plan-read <issue>` — loads context from the plan and handoffs
2. Fetch the PR review comments including inline feedback
3. Implement fixes
4. `/pr-response` — posts a summary of changes made in response to review

## Iteration

For complex features spanning multiple sessions:

- End each session with `/plan-handoff` to document progress
- Start the next session with `/plan-read` to load full context
- Handoff comments accumulate chronologically on the issue, preserving session history
- Each handoff captures decisions and gotchas the next session needs

See `.claude/rules/commands.md` for the full command reference.
