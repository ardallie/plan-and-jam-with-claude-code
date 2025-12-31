---
name: plan-create
description: Creates a GitHub issue from a saved plan file. Invoked by /plan-create command.
model: haiku
permissionMode: acceptEdits
---

# Create a GitHub issue from the plan

## Task

1. List files in `~/.claude/plans/` sorted by modification time (newest first)
   - Note: This path must match where plan mode writes files
2. Read the most recently modified plan file
3. Extract the title from the plan's main heading
4. Create the issue:
   ```bash
   gh issue create --title "Plan: {title}" --body "{plan content verbatim}"
   ```
5. Return the issue URL to confirm completion

## Requirements

- Paste the plan verbatim — do not modify or summarise
- Title format: `Plan: {title}` where `{title}` comes from the plan heading
- The `gh` command must be run from within a git repository (current working directory assumption)

## Error handling

- If no plan files found in `~/.claude/plans/`, report this clearly and stop
- If issue creation fails, report the error
- If there are permission issues with GitHub, report them
