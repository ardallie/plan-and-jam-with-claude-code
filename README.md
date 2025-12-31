# Plan workflow

Multi-session workflow for planning, validating, and implementing features.

## Source of truth

- **Session 1:** Local plan file (`~/.claude/plans/`)
- **Sessions 2+:** GitHub issue

Once the plan is published to GitHub, the issue becomes the single source of truth. Avoid entering plan mode in subsequent sessions — this creates duplicate local files that diverge from the issue.

## Session 1: Create

Design the implementation and publish the plan.

1. Enter plan mode to explore the codebase and design the approach
2. Claude writes the plan to `~/.claude/plans/`
3. `/plan-create` — publishes the plan to a new GitHub issue
4. `/plan-prompt <issue>` — posts the revised prompt as the first comment
5. Keep the session open; validation resumes in a new session for fresh perspective

**Issue structure:**
- Description: Plan (living document, updated via `/plan-update`)
- First comment: Revised prompt (static snapshot of refined requirements)

## Session 2: Validate

Review the plan with fresh context. A new session helps identify gaps and assumptions that were invisible during planning.

1. `/plan-resume <issue>` — loads the plan from GitHub
2. `/plan-validate` — checks clarity, accuracy, and completeness against the codebase
3. `/plan-update` — pushes any revisions back to the issue (if needed)
4. Continue to implementation, or close and resume later

## Session 3: Implement

Execute the plan and document the work.

1. `/plan-resume <issue>` — skip if continuing from session 2
2. Implement the plan
3. `/plan-handoff` — documents what was done as an issue comment
4. `/pr-create` — creates a pull request

## Session 4: Code review

Respond to PR feedback after review.

1. `/plan-resume <issue>` — loads context from the plan
2. Read the PR description (manual) — recall scope and decisions
3. `/pr-fetch-all-comments` — fetches review comments including inline feedback
4. List issues to address from the review (manual)
5. Implement fixes
6. `/pr-response` — posts a summary of changes made in response to review

## Iteration

For complex features spanning multiple sessions:

- End each session with `/plan-handoff` to document progress
- Start the next session with `/plan-resume` to load full context
- Handoff comments accumulate chronologically, preserving session history

See `.claude/rules/commands.md` for the full command reference.
