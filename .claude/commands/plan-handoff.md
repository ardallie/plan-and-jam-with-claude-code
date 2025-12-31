# Post a technical handoff comment to a GitHub issue

## Usage

- `/plan-handoff` - Uses the issue number from conversation context
- `/plan-handoff <issue>` - Posts to the specified issue (e.g., `85`)

## Context

The handoff responds to the plan. The plan defines "what we will do"; the handoff documents "what we actually did". Future sessions use `/plan-resume` to load this context.

## Task

1. Identify the issue number from the argument or search the conversation for a GitHub issue URL or number. If not found, report this and stop.
2. Synthesise implementation details from the conversation
3. Format and post the handoff comment using `gh issue comment <issue> --body "..."`
4. Return the comment URL to confirm completion

## Handoff content

Focus on technical specifics not obvious from the code:

1. **Implementation notes** - Deviations from plan, technical decisions, patterns used
2. **Gotchas** - Import paths, type quirks, environment setup, test mocks required
3. **Verification** - Commands to run tests and lint checks with correct filters
4. **Limitations** - Known constraints, edge cases, incomplete aspects

## Requirements

- Focus on information a future agent needs that isn't visible in the diff
- Include runnable commands with correct package/path filters
- Keep it concise - avoid repeating what's in the plan or PR description

## Error handling

- If issue number cannot be determined, report this clearly and stop
- If issue does not exist, report the error
- If there are permission issues, report them
