# Validate a plan before implementation

## Usage

- `/plan-validate` - Uses the issue number from conversation context
- `/plan-validate <issue>` - Validates the plan from the specified issue (e.g., `85`)

## Context

Use this in session 2 after loading the plan with `/plan-resume`. A fresh session provides perspective that the planning session lacks — assumptions become visible, gaps surface, and ambiguities clarify. This step catches issues before code is written.

## Task

1. Identify the issue number from the argument or search the conversation for a GitHub issue URL or number. If not found, report this and stop.
2. If the plan was already loaded via `/plan-resume`, use the existing context. Otherwise, fetch the issue:
   ```bash
   gh issue view <issue> --json title,body,state
   ```
3. Review the plan against these criteria:
   - **Clarity** — Are the steps unambiguous? Could another agent implement this without guessing?
   - **Accuracy** — Do referenced files, functions, and patterns actually exist? Verify with codebase exploration.
   - **Completeness** — Are edge cases addressed? Are dependencies identified? Is the scope well-bounded?
   - **Feasibility** — Can this be implemented with the current architecture? Are there hidden complexities?
4. Collect additional information:
   - Explore the codebase to verify assumptions made in the plan
   - Check that referenced files and patterns exist as described
   - Identify related code that might be affected
5. Present findings:
   - List any gaps, inaccuracies, or ambiguities found
   - Note verification results (what exists, what doesn't)
   - Ask clarifying questions for items that need user input
6. If the plan is sound, confirm readiness to proceed with implementation

## Requirements

- This is read-only — do not modify the issue
- Verify claims against the actual codebase, not assumptions
- Ask focused questions rather than presenting long lists of possibilities
- Be direct about problems — vague concerns waste time

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
