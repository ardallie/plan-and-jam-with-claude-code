# Create a GitHub issue from the plan

## Usage

- `/plan-create` - Creates an issue from the most recent plan in `~/.claude/plans/`

## Context

This creates a GitHub issue with the plan as the issue description. The issue becomes the single source of truth for subsequent sessions. After creating the issue, run `/plan-prompt` with the issue number to post the revised prompt as the first comment.

## Task

1. Spawn a `plan-create` subagent using the Task tool with `subagent_type: "plan-create"`
2. Return the issue URL from the subagent's response
3. Remind the user to run `/plan-prompt <issue>` to save the revised prompt

## Requirements

- Delegate immediately — do not attempt to read the plan yourself

## Error handling

- If the subagent reports no plan found, ask the user to confirm a plan exists in `~/.claude/plans/`
- If issue creation fails, report the error from the subagent
- If there are permission issues with GitHub, report them
